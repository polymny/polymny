//! This module helps us to run commands.

use std::io::Result;
use std::path::Path;
use std::process::{Command, Output};

use poppler::PopplerDocument;

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
    let document = PopplerDocument::new_from_file(input.as_ref(), "").unwrap();
    let n_pages = document.get_n_pages();

    for i in 0..n_pages {
        let command_input_path = format!("{}[{}]", input.as_ref().to_str().unwrap(), i);
        let command_output_path = format!("{}/{:05}.png", output.as_ref().display(), i);
        let command = vec![
            "convert",
            "-density",
            "300",
            &command_input_path,
            "-resize",
            "1920x1080!",
            &command_output_path,
        ];

        run_command(&command)?;
    }

    Ok(())
}
