
# Preparation
 - [x] afficher le slide / gos
 - [x] ajouter des flèches pour naviguer au slide suivant / précédent
 - [x] remove empty lines / trailing spaces
 - [ ] drag n drop toujours capricieux
 - [ ] scoll vers haut au bas de page si slide drag
 - [x] left column non clickable
 - [ ] pas de zoom / dezoom possible
 - [ ] peut être enlever le pop up et laisser le client se balader (task) conversion PDF/PNG un peu lente
 - [x] impossilité de supprimer un extra
 - [x] impossibilité de drag n drop un extra
 - [x] envoi de slide change pas la vu du grain dans left column
 - [ ] ajouter un slide ne supprime pas le record
 - [ ] feedback sur l'existence du prompt
 - [ ] message d'erreur si cam utilisée

# Aciquisition
 - [x] interdire rec pointer si record playing
 - [x] deuxieme ligne de promteur éditable mais rien ne se passe
 - [x] le prompteur fait des truc chelous quand dans un gos certaines slides ont du prompt et les autres non
 - [x] manque tooltip sur le bouton "enregistrer le pointeur"
 - [ ] ui ne fait pas de diff si on rec la cam ou le pointeur
 - [x] taille du prompteur change sur dernière ligne du promteur
 - [x] manque de ui sur raccourcis clavier
 - [x] manque de ui sur ou on est dans la capsule gos slide
 - [x] pointeur peut se faire désactiver entre slide avec prompt vs sans prompt
 - [ ] clear cache dans les settings ?
 - [x] manque un clear canvas à la fin du record
 - [X] il faut clear proprement quand on change de page
 - [ ] scroll bar dans aqcquisition
 - [ ] si autorisation au mic refusée : inifnite loop binding device

# Production
 - [ ] taille de la webcam : autotriser la chaine vide serait vachement pratique
 - [x] réinitialiser les options ne réinitialise pas la pos de la miniature
 - [x] produire dépublie la capsule mais la capsule reste à published = done
 - [x] format 4:3 fait chier

# Settings
 - [ ] page d'accueil vide
 - [ ] touche entrée ne valide pas
 - [ ] spinning spinner est align right au lieu de center

# Publication
 - [ ] bouton published en bas a droite ?
 - [x] ne pas publier si pas produit

# Global
 - [x] nom projet / capsule dans la navbar ?
 - [ ] title de la page html
 - [x] feedback sur l'etat du websocket ?
 - [x] touche entrée ne valide pas
 - [ ] plus d'info sur les tasks (quelle capsule)
 - [ ] validate e-mail : add trailing slash + redirect
 - [x] disabled button doesn't show up greyed

# Home
 - [x] quotas ont disparu
 - [ ] plus de boutons (copier l'URL de la vidéo)
 - [x] bouton dupliquer la capsule
 - [x] long text sur project name / capsule name


# Extra & Events
Voir les vidéos pas comme des extras mais plutot comme des éléments comme les slides ?

 -> permet de ne pas ajouter une slide inutile pour ajouter une vidéo

 - [ ] Afficher le fait que ce soit une vidéo dans la colonne de gauche.
 - [x] Dans record, afficher la vidéo.
 - [x] Ajouter les listeners sur le player :
    - [x] Play
        ```
        if recording:
            ajouter <record_time>-play-<video_time>
        else:
            retenir que la vidéo est en cours de lecture
        ```
    - [x] Pause
        ```
        if recording:
            ajouter <record_time>-pause-<video_time>
        else:
            retenir que la vidéo est en pause
        ```
    - [x] Jump
        ```
        if recording && playing:
            ajouter <record_time>-play-<video_time>
        elif recording && pause:
            ajouter <record_time>-pause-<video_time>
        ```
    - [x] End -> In fact, End triggers pause.
        ```
        if recording:
            ajouter <record_time>-pause-<video_length>
        else:
            retenir que la vidéo est en pause
            remettre à zero (en pause)
        ```
 - [x] Start recording
    ```
    if playing:
        ajouter 0.0-play-<video_time>
    elif pause:
        ajouter 0.0-pause-<video_time>
    ```
 - [x] Stop recording
    ```
    ajouter <record_time>-pause-<video_time>
    ```
 - [ ] Validation : envoyer les events avec le record
 - [x] Production : recréer la vidéo comme joué lors de l'enregistrement
 - [ ] Production : superposer la vidéo rejoué avec le record (comme on le fait avec les slides mais avec une vidéo)
