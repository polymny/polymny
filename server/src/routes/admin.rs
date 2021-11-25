//! This module contains the routes for admin management.

use tokio::fs::remove_dir_all;

use futures::{poll, task::Poll, StreamExt};

use tungstenite::{Error as TError, Message};

use rocket::http::Status;
use rocket::serde::json::{json, Json, Value};
use rocket::State as S;

use serde::{Deserialize, Serialize};

use crate::config::Config;
use crate::db::capsule::Role;
use crate::db::user::{Admin, User};
use crate::websockets::WebSockets;
use crate::{Db, Error, Result};

/// Admin get dashboard
#[get("/admin/dashboard")]
pub async fn get_dashboard(admin: Admin, db: Db) -> Result<Value> {
    admin.do_stats(&db).await
}

/// Admin get pagniated users
#[get("/admin/users/<page>")]
pub async fn get_users(admin: Admin, db: Db, page: i32) -> Result<Value> {
    admin.get_users(&db, page).await
}

/// Admin get search users
#[get("/admin/searchusers?<username>&<email>")]
pub async fn get_search_users(
    admin: Admin,
    db: Db,
    username: Option<String>,
    email: Option<String>,
) -> Result<Value> {
    if let Some(username) = &username {
        admin.search_by_username(&db, username).await
    } else {
        if let Some(email) = &email {
            admin.search_by_email(&db, email).await
        } else {
            Ok(json!("Nothing"))
        }
    }
}

/// Admin get user id
#[get("/admin/user/<id>")]
pub async fn get_user(admin: Admin, db: Db, id: i32) -> Result<Value> {
    admin.get_user(&db, id).await
}

/// Admin get pagniated capsules
#[get("/admin/capsules/<page>")]
pub async fn get_capsules(admin: Admin, db: Db, page: i32) -> Result<Value> {
    admin.get_capsules(&db, page).await
}

/// Admin get search capsules
#[get("/admin/searchcapsules?<capsule>&<project>")]
pub async fn get_search_capsules(
    admin: Admin,
    db: Db,
    capsule: Option<String>,
    project: Option<String>,
) -> Result<Value> {
    if let Some(capsule) = &capsule {
        admin.search_by_capsule(&db, capsule).await
    } else {
        if let Some(project) = &project {
            admin.search_by_project(&db, project).await
        } else {
            Ok(json!("Nothing"))
        }
    }
}

/// Inviter User form
#[derive(Serialize, Deserialize)]
pub struct InviteUserForm {
    /// The username of the user to invite.
    username: String,

    /// The email address of the user to invite.
    email: String,
}
/// Route to invite user.
#[post("/admin/invite-user", data = "<form>")]
pub async fn request_invite_user(
    admin: Admin,
    db: Db,
    config: &S<Config>,
    form: Json<InviteUserForm>,
) -> Result<()> {
    Ok(admin
        .0
        .request_invitation(form.0.username, form.0.email, &config.mailer, &db, &config)
        .await?)
}

/// The route that deletes a user
#[delete("/admin/user/<id>")]
pub async fn delete_user(_admin: Admin, db: Db, id: i32, config: &S<Config>) -> Result<()> {
    let user = User::get_by_id(id, &db)
        .await?
        .ok_or(Error(Status::NotFound))?;

    let capsules = user.capsules(&db).await?;
    for (capsule, role) in capsules {
        if role == Role::Owner {
            let dir = config.data_path.join(format!("{}", capsule.id));
            remove_dir_all(dir).await?;
            capsule.delete(&db).await?;
        }
    }

    Ok(user.delete(&db).await?)
}

/// A routes that clears unused websockets.
#[get("/admin/clear-websockets")]
pub async fn clear_websockets(_admin: Admin, socks: &S<WebSockets>) -> Result<()> {
    let mut map = socks.lock().await;

    for (_key, val) in &mut *map {
        let mut to_remove = vec![];

        for (i, s) in val.iter_mut().enumerate() {
            let mut count: u32 = 0;
            loop {
                count += 1;

                if count > 50 {
                    // Infinite loop detection
                    to_remove.push(i);
                    info!("INFINITE LOOP DETECTED");
                    break;
                }

                match poll!(s.next()) {
                    Poll::Ready(Some(Err(TError::ConnectionClosed)))
                    | Poll::Ready(Some(Err(TError::AlreadyClosed)))
                    | Poll::Ready(Some(Ok(Message::Close(_)))) => {
                        to_remove.push(i);
                        break;
                    }
                    Poll::Ready(None) | Poll::Pending => break,
                    _ => continue,
                }
            }
        }

        for i in to_remove.iter().rev() {
            if val[*i].close(None).await.is_err() {
                info!("cannot close websocket");
            }
            val.remove(*i);
        }
    }
    Ok(())
}
