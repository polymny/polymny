//! This module contains everything needed to manage web sockets.

use std::collections::HashMap;
use std::sync::Arc;

use futures::{poll, task::Poll, SinkExt, StreamExt};

use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{Mutex, MutexGuard};

use tungstenite::{Error as TError, Message};

use tokio_tungstenite::WebSocketStream;

use ergol::tokio;

use rocket::http::Status;

use crate::config::Config;
use crate::{Error, Result};

/// The struct that holds the websockets.
#[derive(Clone)]
pub struct WebSockets(Arc<Mutex<HashMap<i32, Vec<WebSocketStream<TcpStream>>>>>);

impl WebSockets {
    /// Creates a new empty map of websockets.
    pub fn new() -> WebSockets {
        WebSockets(Arc::new(Mutex::new(HashMap::new())))
    }

    /// Locks the websockets.
    pub async fn lock(&self) -> MutexGuard<'_, HashMap<i32, Vec<WebSocketStream<TcpStream>>>> {
        self.0.lock().await
    }

    /// Send a message to sockets from an id, removing ids that were disconnected.
    pub async fn write_message(&self, id: i32, message: Message) -> Result<()> {
        let mut map = self.lock().await;
        let entry = map.entry(id).or_insert(vec![]);
        let mut to_remove = vec![];

        for (i, s) in entry.into_iter().enumerate() {
            let mut count: u32 = 0;
            let should_remove = loop {
                count += 1;

                if count > 50 {
                    // Infinite loop detection
                    to_remove.push(i);
                    info!("INFINITE LOOP DETECTED");
                    break true;
                }

                match poll!(s.next()) {
                    Poll::Ready(Some(Err(TError::ConnectionClosed)))
                    | Poll::Ready(Some(Err(TError::AlreadyClosed)))
                    | Poll::Ready(Some(Ok(Message::Close(_)))) => {
                        to_remove.push(i);
                        break true;
                    }
                    Poll::Ready(None) | Poll::Pending => break false,
                    _ => continue,
                }
            };

            if !should_remove {
                let res = s.send(message.clone()).await;
                if let Err(TError::ConnectionClosed) = res {
                    to_remove.push(i);
                }
            }
        }

        for i in to_remove.into_iter().rev() {
            if entry[i].close(None).await.is_err() {
                info!("cannot close websocket");
            }
            entry.remove(i);
        }

        Ok(())
    }
}

/// The function called when a connection occurs.
async fn accept_connection(
    websockets: WebSockets,
    stream: TcpStream,
    pool: ergol::Pool,
) -> Result<()> {
    use crate::db::user::User;
    use crate::Db;

    let db = Db::from_pool(pool).await?;

    let mut stream = tokio_tungstenite::accept_async(stream)
        .await
        .expect("Error during the websocket handshake occurred");

    let msg = stream
        .next()
        .await
        .ok_or(Error(Status::InternalServerError))??;

    if let Message::Text(secret) = msg {
        let user = User::get_from_session(&secret, &db)
            .await?
            .ok_or(Error(Status::InternalServerError))?;

        let mut map = websockets.lock().await;
        let entry = map.entry(user.id).or_insert(vec![]);
        entry.push(stream);
    }

    Ok(())
}

/// Starts the webscoket server.
pub async fn websocket(socks: WebSockets, pool: ergol::Pool) {
    let config = Config::from_figment(&rocket::Config::figment());

    // Create the event loop and TCP listener we'll accept connections on.
    let try_socket = TcpListener::bind(&config.socket_listen).await;
    let listener = try_socket.expect("Failed to bind");
    info!("Websocket server listening on: {}", config.socket_listen);

    while let Ok((stream, _)) = listener.accept().await {
        let socks = socks.clone();
        tokio::spawn(accept_connection(socks, stream, pool.clone()));
    }
}
