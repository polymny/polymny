//! This module helps us to run commands.

use std::io::Result;
use std::path::Path;
use std::process::{Command, Output};

/// Runs a specified command.
pub fn run_command(command: &Vec<&str>) -> Result<Output> {
    info!("Running command: {:?}", command);
    let child = Command::new(command[0]).args(&command[1..]).output();

    match &child {
        Err(e) => error!("Command failed: {}", e),
        Ok(o) if !o.status.success() => error!(
            "Command failed with code {}:\n\nSTDOUT\n{}\n\nSTDERR\n{}\n\n",
            o.status,
            String::from_utf8(o.stdout.clone())
                .unwrap_or_else(|_| String::from("Output was not utf8, couldn't read stdout")),
            String::from_utf8(o.stderr.clone())
                .unwrap_or_else(|_| String::from("Output was not utf8, couldn't read stderr")),
        ),
        _ => (),
    }

    child
}

/// Exports all slides from pdf to png.
pub fn export_slides<P: AsRef<Path>, Q: AsRef<Path>>(input: P, output: Q) -> Result<()> {
    run_command(&vec![
        "pdftocairo",
        "-png",
        "-scale-to-x",
        "1920",
        "-scale-to-y",
        "1080",
        input.as_ref().to_str().unwrap(),
        &format!("{}/", output.as_ref().to_str().unwrap()),
    ])?;

    Ok(())
}
