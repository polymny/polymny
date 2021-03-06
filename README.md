<p align="center">
<img src="/samples/polymny.png"
     alt="Polymny logo"
     width="150"
     style="align:center" />
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

  - [Building](#building)
    - [Building the client](#client)
    - [Building the server](#server)
      - [Installating Rust](#install-rust)
      - [Setting up the database](#database-setup)
      - [Configuring the server](#configuration)
  - [Running](#running)
  - [Developping](#developping)

## Building


The following sections explain how to build the client and the server.

### Client

You'll need to intall [elm](https://guide.elm-lang.org/install.html) in order
to be able to build the client.

We recommend that you install elm with
[nvm](https://github.com/creationix/nvm#installation).

Once `elm` is installed, you should be able to run `make client-dev` in the
root of the repository to build the client.

### Server

#### External packages

Install the following package before rust compilation:

```
sudo apt install libpoppler-glib-dev
```


#### Install Rust

You'll need to install [rust-nightly](https://www.rust-lang.org/tools/install)
in order to be able to build the server. We recommend that you install rust
with rustup, so you can install rust nightly by running
`rustup toolchain add nightly`.

You have three tways to build the server with nightly:
  - you can simple run `make server-dev` at the root of the directory,
  - if you feel more confortable with using cargo, you can go to the server
    directory, run `rustup override set nightly`, and then you'll be able to
    `cargo build` freely,
  - or you can `cargo +nightly build` in the server directory.

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


#### Matting

Matting is the process of background removal when the speaker is not in front
of a green screen. In order to enable matting, certain steps must be done:

  - the repository must be cloned at the same level where polymny is:
    ```
    git clone https://gitlab.enseeiht.fr/tforgione/Background-Matting
    ```
    (this step may take a little time because it also downloads the network)

  - you also need an [anaconda](https://www.anaconda.com/distribution/)
    environment. Anaconda must be installed in `~/.anaconda3`. You then create
    the environment for the background matting:
    ```
    conda create --name back-matting python=3.6
    conda activate back-matting
    ```

  - you need to install Cuda 10.0. You need to export some variables for the
    server to be able to find cuda, e.g., if your cuda is in
    `/usr/local/cuda-10.0`, you can do
    ```
    export LD_LIBRARY_PATH=/usr/local/cuda-10.0/lib64
    export PATH=$PATH:/usr/local/cuda-10.0/bin
    ```

  - you can then install the dependencies of the background matting software:
    ```
    conda install pytorch=1.1.0 torchvision cudatoolkit=10.0 -c pytorch
    pip install tensorflow-gpu==1.14.0
    pip install -r requirements.txt
    ```

#### Configuration

Once you've created the database, you need to write the configuration file.
This file should be in `server/Rocket.toml` and should define some parameters.
Here is an example of a minimal configuration file for development:

```
[development]
root = "http://localhost:8000"
secret_key = "eH/ZsKc5sJMD1/yr2HliA1XPlB3v6aT0Gv9pcRwQaYs="

[global.databases.database]
url = "postgres://<username>:<password>@localhost:5432/<dbname>"
```

A secret key can be generated by running `openssl rand -base64 32`.

Also, if you want to enable the background matting, you need to add the
following variable to the development section of your `Rocket.toml`:

```
matting_enabled = true
```

The last thing that needs to be done is it initialize the database. For this,
you will need `diesel_cli`. You can install it like so:

```
cargo install diesel_cli --no-default-features --features postgres
```

Once `diesel_cli` is installed, you will be able to initialize the database by
running:

```
diesel migration run --database-url <database-url>
```

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
directory, and you run `cargo run` or `cargo +nightly run` depending on whether
you overrode the toolchain.

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


