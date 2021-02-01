//! This module contains the routes and task management.

use std::io::{BufRead, BufReader};

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use crate::command;
use crate::db::task::{Task, TaskStatus};
use crate::db::user::User;
use crate::schema::tasks;
use crate::{Database, Result, WebSockets};

/// Manage a task/ subrocess
pub struct TaskManager<'a> {
    /// The id of the user
    pub user_id: i32,
    /// The database connection.
    pub db: &'a Database,
    /// the task
    task: Task,
    /// the child Process
    child: Option<std::process::Child>,
}

impl<'a> TaskManager<'a> {
    /// create new task
    pub fn new(db: &'a Database, user_id: i32) -> Result<TaskManager> {
        let task = Task::new(user_id, "spawn task", db)?;
        let manager = TaskManager {
            user_id,
            db,
            task,
            child: None,
        };
        Ok(manager)
    }

    /// start a process with child
    pub fn spawn(&mut self, command: &Vec<&str>) -> Result<()> {
        self.child = Some(command::spawn_command(&command).unwrap());
        use crate::schema::tasks::dsl;
        diesel::update(tasks::table)
            .filter(dsl::id.eq(self.task.id))
            .set((dsl::state.eq(TaskStatus::Running), dsl::progress.eq(0.0)))
            .execute(&self.db.0)?;

        Ok(())
    }

    /// success on child end ?
    pub fn success(&mut self) -> bool {
        match self.child.as_mut() {
            Some(child) => {
                let ret = child.wait().expect("failed to wait on child");
                ret.success()
            }
            None => false,
        }
    }

    /// Manage ffmpeg task progress
    pub fn ffmpeg_task_progress(&mut self, socks: &WebSockets) -> Result<()> {
        use crate::schema::tasks::dsl;
        match self.child.as_mut() {
            Some(child) => {
                let user = User::get_by_id(self.task.user_id, self.db)?;
                println!("child id = {}", child.id());
                let stdout = child.stdout.take().unwrap();
                let reader = BufReader::new(stdout);
                let mut total_frames = 1;
                for line in reader.lines() {
                    let bidule = line.unwrap();
                    let data = bidule.split("=").collect::<Vec<_>>();
                    match data[..] {
                        ["frame", x] => {
                            let frames = x.parse::<i32>().unwrap();
                            let progress = ((frames as f32) / total_frames as f32) * 100.;
                            println!("frame count = {:#?} -  progress= {:.2}%", frames, progress);
                            diesel::update(tasks::table)
                                .filter(dsl::id.eq(self.task.id))
                                .set(dsl::progress.eq(progress as f64))
                                .execute(&self.db.0)?;

                            user.task_progress(socks, self.task.id, self.db)?;
                        }
                        ["total_frames", x] => {
                            total_frames = x.parse::<i32>().unwrap();
                            println!("total_frames  {:#?}", total_frames);
                        }
                        _ => {}
                    };
                }
                diesel::update(tasks::table)
                    .filter(dsl::id.eq(self.task.id))
                    .set((dsl::state.eq(TaskStatus::Done), dsl::progress.eq(100.0)))
                    .execute(&self.db.0)?;
            }
            None => return Ok(()),
        }
        Ok(())
    }
}
