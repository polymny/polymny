<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/server/dist/fulllogo-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="/server/dist/fulllogo.png">
  <img alt="Polymny Studio" src="/server/dist/fulllogo.png">
</picture>
</p>

<p align="center">
<em>
Polymny is a web based tool for easy production of educational videos.
<br/>
You just need some slides in PDF and web browser!
</em>
</p>

[![CI](https://github.com/polymny/polymny/workflows/build/badge.svg?branch=master&event=push)](https://github.com/polymny/polymny/actions?query=workflow%3Abuild)

This project consists in a backend written in
[rust](https://www.rust-lang.org/) and a front end in
[elm](https://elm-lang.org/).


## Table of contents

  - [Fonctionnalités](#Fonctionnalités)
  - [Building](#building)
    - [Getting the source code](#getting-the-source-code)
    - [Building the client](#client)
    - [Building the server](#server)
      - [Installating Rust](#install-rust)
      - [Setting up the database](#database-setup)
      - [Configuring the server](#configuration)
  - [Running](#running)
  - [Developping](#developping)

## Fonctionnalités

Se concentrer sur le fond de son discours plutôt que de se perdre dans la technique. 100 % en ligne, le logiciel libre Polymny Studio permet – dès sa version gratuite – de créer, modifier et diffuser rapidement et facilement des vidéos informatives ou formatives sans aucune compétence particulière en montage vidéo ou en hébergement web. Il suffit de charger une présentation pdf sur la plateforme et de se lancer. Un véritable jeu d’enfant. Des fonctionnalités complémentaires (stylet et fond vert virtuels, approche collaborative…) sont disponibles dans sa version pro.

### Préparer capsule

L'application permet de télécharger un support au format pdf et de l'organiser en séquences d'enregistrement appelé "grain".
Pour dynamiser la vidéo: l'application permet de remplacer une planche par vidéo externe (jingle, capture d'écran, animations, ...).
L'édition d'un prompteur permettra de bien adapté le discours au support de cours

### Enregistrer depuis une caméra

Pour chaque grain, il est facile de  faire (et refaire) un enregistrement vidéo (ou audio seul). Le prompteur est affiché pour vous guider.
Si vous avez plusieurs caméra, webcam ou micros vous pouvez choisir celui qui convient le mieux.

### Produire une capsule vidéo

Une fois les enregistrements terminés, quelques options simples de montage (ajustable grain par grain):
- Réglage (taille, position et transparence) de  l'enregistrement caméra a dessus du support de cours.
- mode audio seul (pas de caméra).

La vidéo produite peut être téléchargée. Nous vous recommandons, néanmoins, de passer par la publication de la vidéo afin de ne pas multiplier le stockage de vidéo

### Publication d'une capsule vidéo

Publier une vidéo, consiste à générer une URL de partage  de la vidéo. Cette URL est adaptée eu besoin de partage et de diffusion d'une vidéo. Exemple [https://polymny.studio/v/3ML6p/](https://polymny.studio/v/3ML6p/).
Pour chaque vidéo publié la confidentialité est paramétrable, par exemple une diffusion restreinte à quelques utilisateurs ou bien publique.

### Modifier des capsules existantes
Chaque capsule (même publiée) peut-être rapidement corrigée ou modifiée comme par exemple refaire un enregistrement, modifier une planche, ou ajouter du contenu.
Toutes les données d'une capsule (planches, enregistrements,  texte de prompteur) sont exportables sous forme d'archive ZIP.







## Building

The following sections explain how to build the client and the server.

### Getting the source code

The first step is to download the source code. There are two pieces of software
required for polymny:
  - [polymny](https://github.com/polymny/polymny): the polymny source code
  - [hls](https://github.com/polymny/hls): the script that encodes videos in
    HLS format for streaming

You need to clone these two repositories at the same level in your file system:

```sh
git clone https://github.com/polymny/hls
git clone https://github.com/polymny/polymny
```

### Client

You'll need to intall [elm](https://guide.elm-lang.org/install.html) in order
to be able to build the client.

We recommend that you install elm with
[nvm](https://github.com/creationix/nvm#installation).

Once `elm` is installed, you should be able to run `make client-dev unlogged-dev`
in the
root of the repository to build the client.

### Server

#### External packages

Install the following package before rust compilation:

```
sudo apt install libpoppler-glib-dev qpdf imagemagick ffmpeg jq bc
```

You may need to remove the PDF line from `/etc/ImageMagick-<X>/policy.xml`
(where `<X>` is your image magick version) if an error occurs during the PDF
import.

#### Install Rust

You'll need to install [rust](https://www.rust-lang.org/tools/install)
in order to be able to build the server. We recommend that you install rust
with rustup.

You have two tways to build the server:
  - you can simple run `make server-dev` at the root of the directory,
  - or you can `cargo build` in the server directory.

#### Database setup

The server requires a postgresql database. The best way is to create a postgres
user and a database for it. On most operating systems, you need to use the
postgres user:

```
sudo su postgres
```

Once that's done, you can create a user and enter its password like this:

```
createuser -P <username>
```

and then, create a database for the user:

```
createdb <dbname> -O <username>
```

You can then run

```
exit
```

to get back to your normal user.

#### Configuration

Once you've created the database, you need to write the configuration file.
This file should be in `server/Rocket.toml` and should define some parameters.
Here is an example of a minimal configuration file for development:

```
[default]
root = "http://localhost:8000"
video_root = "http://localhost:8000/v"

websocket_listen = "localhost:8001"
websocket_root = "ws://localhost:8001"

harsh_length = 5
harsh_secret = "XMmoJdfbnnI2ZQMz3wjp8itoSkngFoarFD4wiH6ZRaU="

secret_key = "eH/ZsKc5sJMD1/yr2HliA1XPlB3v6aT0Gv9pcRwQaYs="

[default.databases.database]
url = "postgres://<username>:<password>@localhost:5432/<dbname>"
```

The secret key and the harsh secret can be generated by running `openssl rand -base64 32`.
The harsh length is the minimum length of capsule ids which are hash ids.

Once the database is configured in the `server/Rocket.toml` file, you'll need
to install `ergol_cli` to initialize it:

```
cargo install ergol_cli
```

Once this is done, you need to run the migrations, which will create and
initializes the tables. Go to the server directory, and then run

```
ergol migrate
```

[You can find more documentation on ergol here](https://ergol-rs.github.io/)

#### Mailer configuration

If you want, you can also configure the mailer in the `server/Rocket.toml` file.
Doing so allows the server to send email, and thus, to verify users email.
Here is a template of mailer configuration:

```
[global]
mailer_enabled = true
mailer_host = "<smtp-server-url>"
mailer_user = "<user-for-smtp-auth>"
mailer_password = "<password-for-smtp-auth>"
mailer_from = "<from-header-of-email>"
```

## Running

Once you've built and configured everything, you just go to the server
directory, and you run `cargo run`.

## Developping

You can install `elm-live` and run `make client-watch` at the root of the
repository. When a change will be made to the client, `elm-live` will rebuild
the client, and it will serve a static server on port 7000.  However, this is
not what you want, you need to start the rust server by going in the server
directory and running `cargo build` or `cargo +nightly build`, and test on
[localhost:8000](http://localhost:8000).

The rust server will always serve the latest version of the static files, so
you don't need to restart the rust server everytime if you only modified the
client.


