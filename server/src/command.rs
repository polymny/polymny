//! This module helps us running commands.

use std::path::Path;
use std::process::{Command, Output};
use std::result::Result as StdResult;

use uuid::Uuid;

use rayon::prelude::*;

use rocket::http::Status;

use crate::config::Config;
use crate::{Error, Result};

/// Runs a specified command.
pub fn run_command(command: &Vec<&str>) -> Result<Output> {
    info!("Running command: {:#?}", command.join(" "));

    let child = Command::new(command[0]).args(&command[1..]).output();
    match &child {
        Err(e) => error!("Command failed: {}", e),
        Ok(o) if !o.status.success() => {
            error!(
                "Command failed with code {}:\n\nSTDOUT\n{}\n\nSTDERR\n{}\n\n",
                o.status,
                String::from_utf8(o.stdout.clone())
                    .unwrap_or_else(|_| String::from("Output was not utf8, couldn't read stdout")),
                String::from_utf8(o.stderr.clone())
                    .unwrap_or_else(|_| String::from("Output was not utf8, couldn't read stderr")),
            );

            return Err(Error(Status::InternalServerError));
        }
        _ => (),
    }

    child.map_err(|_| Error(Status::InternalServerError))
}

/// Runs a specified command.
pub fn run_command_with_output(command: &Vec<&str>) -> Result<Output> {
    info!("Running command: {:#?}", command.join(" "));
    let mut child = Command::new(command[0]);
    let child = child.args(&command[1..]);
    let child = child.spawn()?;

    let child = child.wait_with_output();

    match &child {
        Err(e) => error!("Command failed: {}", e),
        Ok(o) if !o.status.success() => {
            error!(
                "Command failed with code {}:\n\nSTDOUT\n{}\n\nSTDERR\n{}\n\n",
                o.status,
                String::from_utf8(o.stdout.clone())
                    .unwrap_or_else(|_| String::from("Output was not utf8, couldn't read stdout")),
                String::from_utf8(o.stderr.clone())
                    .unwrap_or_else(|_| String::from("Output was not utf8, couldn't read stderr")),
            );

            return Err(Error(Status::InternalServerError));
        }
        _ => (),
    }

    child.map_err(|_| Error(Status::InternalServerError))
}

/// Counts the pages of a PDF file.
pub fn count_pages<P: AsRef<Path>>(input: P) -> Result<u32> {
    let output = run_command(&vec![
        "qpdf",
        "--show-pages",
        input
            .as_ref()
            .to_str()
            .ok_or(Error(Status::InternalServerError))?,
    ])?;

    let mut count = 0;

    for line in std::str::from_utf8(&output.stdout)
        .map_err(|_| Error(Status::InternalServerError))?
        .lines()
    {
        if line.starts_with("page") {
            count += 1;
        }
    }

    Ok(count)
}

/// Exports all slides (or one) from pdf to png.
pub fn export_slides<P: AsRef<Path>, Q: AsRef<Path> + Send + Sync>(
    config: &Config,
    input: P,
    output: Q,
    page: Option<i32>,
) -> Result<Vec<Uuid>> {
    let pdf_target_size = config.pdf_target_size.clone();
    let pdf_target_density = config.pdf_target_density.clone();
    match page {
        Some(x) => {
            let command_input_path = format!(
                "{}[{}]",
                input
                    .as_ref()
                    .to_str()
                    .ok_or(Error(Status::InternalServerError))?,
                x
            );
            let uuid = Uuid::new_v4();
            let command_output_path = format!(
                "{}/{}.png",
                output
                    .as_ref()
                    .to_str()
                    .ok_or(Error(Status::InternalServerError))?,
                uuid
            );
            run_command(&vec![
                "../scripts/psh",
                "pdf-to-png",
                &command_input_path,
                &command_output_path,
                &pdf_target_density.to_string(),
                &pdf_target_size.to_string(),
            ])?;

            Ok(vec![uuid])
        }

        None => {
            let vec: Vec<u32> = (0..count_pages(&input)?).collect();
            let vec_in = vec
                .iter()
                .map(|i| match input.as_ref().to_str() {
                    Some(o) => Ok(format!("{}[{}]", o, i)),
                    _ => Err(Error(Status::InternalServerError)),
                })
                .collect::<StdResult<Vec<_>, _>>()?;

            let result = vec_in
                .par_iter()
                .map(|filepath| {
                    let uuid = Uuid::new_v4();
                    let filepath_out = format!(
                        "{}/{}.png",
                        output
                            .as_ref()
                            .to_str()
                            .ok_or(Error(Status::InternalServerError))?,
                        uuid
                    );
                    let _res = run_command(&vec![
                        "../scripts/psh",
                        "pdf-to-png",
                        filepath,
                        &filepath_out,
                        &pdf_target_density,
                        &pdf_target_size,
                    ])?;

                    Ok(uuid)
                })
                .collect::<Result<Vec<_>>>()?;

            Ok(result)
        }
    }
}
