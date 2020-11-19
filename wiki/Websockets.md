# À propos de l'utilisation des WebSockets dans Polymny

## Communication serveur vers client.

Dans les architectures HTTP classiques, le client envoie une requête à un
serveur, et le serveur envoie une réponse au client. Dans la specification
HTTP, il n'y a donc aucun moyen pour le serveur de spontanément contacter le
client : le client doit nécessairement envoyer une requête au serveur pour que
le serveur puisse lui envoyer de l'information.

Pour remédier à ce problème, il y a eu plusieurs techniques et technologies.

### La méthode dégueu des années 80

Le client envoie des requêtes au serveur toutes les n secondes, et si le
serveur a quelque chose à dire, il le dit. On pourrait faire ca en elm, envoyer
des XHR dans un `setInterval` mais c'est dégueu, ça spamme le serveur et c'est
nul.

### La méthode un peu moins dégueu : le Server Sent Event

Le principe, c'est que le client ouvre une requête HTTP avec un timeout super
long, et le serveur la maintient ouverte jusqu'à ce qu'il ait besoin d'envoyer
une notification au client, auquel cas il répond et le client envoie une
nouvelle requête pour une future notification. Ça s'appelle les [Server Sent
Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
et c'est plutôt cool, mais Rocket (pour ceux qui connaissent pas, c'est la
librairie qu'on utilise pour écrire le serveur) supporte pas les Server Sent
Events, et j'suis pas hyper à l'aise à l'idée de coder moi-même ce mécanisme à
la main, d'autant que les problèmes qui arrivent sont similaires à ceux qui
arrivent avec les websockets...

### Les Websockets

Les websockets, c'est un peu le truc ultime. Non seulement, le serveur peut
contacter spontanément le client, mais en plus le client peut envoyer des
messages au serveur de manière plus légère (je crois ?) qu'en passant par une
requête HTTP. C'est peut-être pas aussi léger que les server sent events, mais
c'est mieux supporté, et on peut facilement faire des serveurs websockets en
rust, donc on peut se contenter de faire tourner deux serveurs : un serveur
HTTP écrit avec rocket et un serveur websocket qui tourne à côté, malgré le
fait que rocket ne supporte pas directement les websockets *(non plus)*. La
problématique vient de la communication entre les deux serveurs, et c'est cette
communication qui est décrite dans la suite.

## La solution que j'ai implémenté.

### `Arc<Mutex<HashMap<i32, WebSocket<Vec<TcpStream>>>>>`

L'idée, c'est d'avoir un serveur HTTP écrit en Rocket qui gère les requêtes
HTTP, et un autre serveur, dans le même programme que le serveur HTTP, qui va
s'occuper des websockets. Du coup, le serveur HTTP s'occupe de tout ce qui a
déjà codé, et le serveur websockets laisse les clients se connecter et gère les
notifications. Le problème, c'est que c'est le serveur HTTP qui doit envoyer
les notifications, et du coup, il faut que les deux serveurs (qui tournent sur
des threads différents) communiquent. Pour ça, j'utilise une mémoire partagée.
Là, on est bien content d'être en Rust, grace à ce qu'on appelle la *fearless
concurrency*, et la capacité de Rust à rattraper toutes les erreurs de
programmation de systèmes concurrents, directement à la compilation.

Du coup, j'ai défini un type

``` rust
pub struct WebSockets(Arc<Mutex<HashMap<i32, Vec<WebSocket<TcpStream>>>>>);
```

Le type `WebSocket<TcpStream>`, est le type qui permet de recevoir et d'envoyer
des messages sur des websockets. Je les range dans une
`HashMap<i32, Vec<WebSocket<TcpStream>>>` qui me permet d'associer les id des
users aux sockets adéquats. J'ai besoin du `Vec` au cas où un utilisateur ait
plusieurs onglets ouverts, et donc plusieurs websockets ouverts.

Ensuite, il reste `Arc<Mutex<_>>`.
[`Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html) *(Atomically
Reference Counted shared pointer)*, c'est un pointeur qui est fait pour être
partagé sur plusieurs threads. À l'exécution du programme, il y a un entier qui
compte le nombre de référence, quand l'`Arc` est cloné, le compteur incrémente,
et quand un `Arc` est détruit le compteur décrémente. Quand le compteur atteint
0, la mémoire est libérée (du coup, il ne faut pas avoir de cycle de `Arc`
parce que sinon ça fait une fuite mémoire, ce qui ne devrait à priori pas poser
de problèmes puisque le pointeur contient juste un websocket, donc pas d'autres
pointeurs).

Ensuite arrive le problème de la mutabilité. `Arc<T>` n'est pas mutable (parce
que potentiellement, plusieurs threads pourraient vouloir le muter en même
temps). Pour régler ce problème, en Rust, il y a un concept qu'on appelle
l'*interior mutability*. J'avoue ne pas avoir compris les détails, mais
en gros, le `Arc<T>` ne sera pas muté, mais le `T` le sera pourvu qu'il
respecte certaines règles (tout ça sera vérifié à la compilation). Vu qu'on a
besoin de muter notre `HashMap`, on va utiliser un `Mutex` qui garantit que les
deux threads ne modifient pas notre `HashMap` en même temps.

Ensuite, je nomme ce type `WebSockets` parce qu'il est long à écrire et qu'on
va avoir besoin de l'écrire souvent.

Le serveur websocket va avoir une copie de ce pointeur, et attends les
connexions, authentifie les gens, et les rajoute à la HashMap.

De l'autre côté, le serveur HTTP peut accéder à ce pointeur via un fairing
(explications après) et donc retrouver le websocket correspondant à un user,
pour lui envoyer des notifications.

### Le fairing

Les fairings, en Rocket, c'est des infos qu'on peut calculer pour traiter les
requêtes. Du coup on a un fairing qui correspond à ce fameux type `WebSockets`,
et si d'habitude, on avait une route comme ça :

```rust
#[get("/")]
pub fn route() {
    // Do stuff
}
```

on peut maintenant écrire ça :

```rust
#[get("/")]
pub fn route(sockets: State<WebSockets>) {
    // Do more stuff
    // Use sockets to send notifications
}
```

### Les notifications côté serveur

Dans la dernière migration, j'ai rajouté une table `notifications` :

```sql
CREATE TYPE notification_style AS ENUM ('info', 'warning', 'error');

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id),
    title VARCHAR NOT NULL,
    content VARCHAR NOT NULL,
    style notification_style NOT NULL,
    read BOOLEAN NOT NULL DEFAULT false
)
```

J'ai l'impression que c'est important que les notifications soient stockées en
base de données, parce que si quelqu'un démarre une tâche et qu'il se barre et
que la tâche termine pendant qu'il est pas là, le socket est fermé et du coup,
pas de notifs. Au moins en la stockant en base de données, on sait qu'on sera
capable de la récupérer quand le client se connectera.

#### Implémentation

##### Le serveur websocket

Le serveur websocket est un serveur lancé au démarrage en parallèle à notre
serveur HTTP. Il tourne nécessairement sur un autre port puisque le serveur
HTTP occupe déjà le port 80. Ce serveur est chargé d'accueillir les nouvelles
connexions sur les websockets et les enregistrer dans le type décrit
précédemment.

Le code du serveur websocket est le suivant :

```rust
pub fn start_websocket_server(config: rocket::Config, socks: WebSockets) {
    let server_config = Config::from(&config);

    let database_url = config
        .get_table("databases")
        .unwrap()
        .get_key_value("database")
        .unwrap()
        .1
        .as_table()
        .unwrap()
        .get_key_value("url")
        .unwrap()
        .1
        .as_str()
        .unwrap()
        .to_owned();

    let root = server_config
        .socket_root
        .split("/")
        .skip(2)
        .collect::<Vec<_>>()
        .join("/");

    let server = TcpListener::bind(&root).unwrap();
    for stream in server.incoming() {
        let socks = socks.clone();
        let database_url = database_url.clone();
        thread::spawn(move || {
            let mut websocket = accept(stream.unwrap()).unwrap();
            let msg = websocket.read_message().unwrap();

            let db = PgConnection::establish(&database_url)
                .unwrap_or_else(|_| panic!("Error connecting to {}", database_url));

            if let Message::Text(secret) = msg {
                let user = User::from_session(&secret, &db).unwrap();
                let mut map = socks.lock().unwrap();
                let entry = map.entry(user.id).or_insert(vec![]);
                websocket.get_mut().set_nonblocking(true).ok();
                entry.push(websocket);
            }
        });
    }
}
```

Le début de la fonction initialise les paramètres nécessaires à l'exécution du
serveur (récupération de l'adresse sur laquelle le serveur tourne, l'adresse de
connexion à la base de données, etc...).

Ensuite, pour chaque connexion, le serveur démarre un thread qui écoute le
websocket. Pour l'instant, celui-ci est bloquant, et on attend que le client
envoie son cookie d'authentification. Le serveur se connecte ensuite à la base
de données, retrouve l'utilisateur correspondant au cookie, et enregistre le
websocket dans le type défini précédemment, en l'associant au bon utilisateur.

La dernière chose que fait le serveur est passer le socket en mode
non-bloquant. En effet, dans le traitement des websockets, nous avons besoin de
lire les messages envoyés par le client, pour savoir si celui-ci est toujours
connecté. Si le socket est bloquant, le serveur risque de se retrouver bloquer
à attendre un message sur un websocket ce qui n'est pas souhaitable.

##### Envoi de messages

Sur notre type, j'ajoute une fonction `write_message` permettant d'envoyer un
message sur un websocket. Cette fonction est implémentée ainsi :

```rust
pub fn write_message(&self, id: i32, message: Message) {
    let mut map = self.lock().unwrap();
    let entry = map.entry(id).or_insert(vec![]);
    let mut to_remove = vec![];

    for (i, s) in entry.into_iter().enumerate() {
        loop {
            match s.read_message() {
                Err(TError::ConnectionClosed) | Err(TError::AlreadyClosed) => {
                    to_remove.push(i);
                    break;
                }
                Err(TError::Io(e)) if e.kind() == io::ErrorKind::WouldBlock => break,
                _ => continue,
            }
        }
        s.write_message(message.clone()).ok();
    }

    for i in to_remove.into_iter().rev() {
        entry.remove(i);
    }
}
```

Elle prend en paramètre l'id de l'user auquel il faut envoyer le message, et le
message à envoyer. Elle lock les websockets, récupère les websockets concernant
l'id de l'user en question, puis itère sur ces websockets.

Il est important que le serveur soit capable de lire les messages sur les
websockets pour savoir s'ils ont été fermés ou non. Pour l'instant, je ne vois
pas de raison pour que le client contacte le serveur via le websocket, donc le
serveur se contente de lire les messages pour vérifier que les sockets soient
toujours ouverts, et peut donc le faire juste avant d'envoyer un message.

Il est important à ce niveau là que le stream à l'intérieur du websocket soit
non bloquant : s'il était bloquant, les notifications ne seront pas envoyées
puisque le serveur attendra de recevoir un message sur le premier socket. Ici,
on veut juste consommer les messages qui sont déjà arrivés.

On enregistre les indices des sockets ayant été fermés pour les enlever de la
liste des websockets, et on passe au socket suivant dès que la lecture du
message renvoie `WouldBlock`, c'est-à-dire qu'il n'y a plus de message à lire
sur le socket.

#### Utilisation

Voici un exemple réel d'envoi de notification :

```rust
/// The route to publish a video.
#[post("/capsule/<id>/publication")]
pub fn capsule_publication(
    config: State<Config>,
    db: Database,
    user: User,
    id: i32,
    socks: State<WebSockets>,
) -> Result<()> {

    // Lancer tous les scripts permettant la publication d'une vidéo (long)


    // On récupère les websockets depuis le fairing.
    let socks = socks.inner();

    // On envoie une notification à l'utilisateur.
    // Cette ligne enregistre la notification en base de données, et envoie
    // une notification sur le websocket si le client est connecté.
    user.notify(
        &socks,
        NotificationStyle::Info,
        "Publication terminée !",
        &format!("La capsule {} est publiée.", capsule.name),
        &db,
    )?;
}
```

### Les notifications côté client

Côté client, j'ai fait un type `Notifcation` qui mimique le type côté serveur,
avec un petit `Json.Decoder`. Dans la session, j'ai rajouté une `List
Notifcation`, et le serveur envoie les notifs dans la session à la connexion,
puis les nouvelles notifs par le websocket. Pas grand chose à dire du coup,
j'ai mis un booléen dans `Core.Global` pour dire si le panneau de notifications
doit être ouvert ou pas. J'aurais pu le mettre dans session, ça aurait
probablement été plus simple, *but it just feels wrong*.

