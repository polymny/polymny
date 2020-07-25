//! This module helps us to run commands.

use poppler::PopplerDocument;
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
    println!(
        "input = {:#?}, output = {:#?} ",
        input.as_ref().to_str().unwrap(),
        &format!("{}/", output.as_ref().to_str().unwrap())
    );
    let document = PopplerDocument::new_from_file(&input, "").unwrap();
    info!("PDF doc = {:#?}", document.get_metadata());
    let n_pages = document.get_n_pages();
    for i in 0..n_pages {
        //  convert ~/Bureau/pdf43.pdf -colorspace RGB -resize 1920x1080 -background white -gravity center -extent 1920x1080 /tmp/pdf43.png
        let command_input_path = format!("{}[{}]", input.as_ref().to_str().unwrap(), i);
        let command_output_path = format!("{}/{:05}.png", output.as_ref().display(), i);
        let command = vec![
            "convert",
            "-density",
            "120",
            &command_input_path,
            "-colorspace",
            "RGB",
            "-resize",
            "1920x1080",
            "-background",
            "white",
            "-gravity",
            "center",
            "-extent",
            "1920x1080",
            &command_output_path,
        ];
        run_command(&command)?;
    }

    Ok(())
}
