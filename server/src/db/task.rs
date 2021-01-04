//! This module contains the structures needed to manipulate tasks.

use diesel::prelude::*;

use crate::schema::tasks;
use crate::{Database, Result};

#[allow(missing_docs)]
mod task_status {
    /// The different published states possible.
    #[derive(Debug, PartialEq, Eq, DbEnum, Serialize, Copy, Clone)]
    pub enum TaskStatus {
        /// Not started.
        Idle,

        /// Running.
        Running,

        /// Done.
        Done,
    }
}

pub use task_status::TaskStatusMapping as Task_status;
pub use task_status::{TaskStatus, TaskStatusMapping};

/// Task for long running executions
#[derive(Identifiable, Queryable, Associations, PartialEq, Debug, Serialize)]
#[table_name = "tasks"]
pub struct Task {
    /// The id of the tasks.
    pub id: i32,

    /// The owner of the task.
    pub user_id: i32,

    /// The PID of the task
    pub pid: i32,

    /// The task description.
    pub content: String,

    ///  the progress in percent of a task
    pub progress: f64,

    /// The style of the notification.
    pub state: TaskStatus,
}

impl Task {
    /// Creates a new notofication and stores it in the database.
    pub fn new(user_id: i32, content: &str, db: &Database) -> Result<Task> {
        Ok(NewTask {
            pid: -1,
            user_id,
            content: content.to_owned(),
            progress: 0.0,
            state: TaskStatus::Idle,
        }
        .save(&db)?)
    }

    /// Gets a task by id.
    pub fn get_by_id(id: i32, db: &Database) -> Result<Task> {
        use crate::schema::tasks::dsl;
        Ok(dsl::tasks
            .filter(dsl::id.eq(id))
            .get_result::<Task>(&db.0)?)
    }
}

/// A new task not stored in the database yet.
#[derive(Debug, Insertable)]
#[table_name = "tasks"]
pub struct NewTask {
    /// The PID of the task
    pub pid: i32,

    /// The owner of the task.
    pub user_id: i32,

    /// The task description.
    pub content: String,

    ///  the progress in percent of a task
    pub progress: f64,

    /// The style of the notification.
    pub state: TaskStatus,
}

impl NewTask {
    /// Saves a notification.
    pub fn save(&self, db: &Database) -> Result<Task> {
        Ok(diesel::insert_into(tasks::table)
            .values(self)
            .get_result(&db.0)?)
    }
}
