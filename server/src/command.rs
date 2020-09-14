//! This module helps us to run commands.

use std::io::Result;
use std::path::Path;
use std::process::{Command, Output};

use poppler::PopplerDocument;
extern crate ffmpeg_next as ffmpeg;

/// Runs a specified command.
pub fn run_command(command: &Vec<&str>) -> Result<Output> {
    info!("Running command: {:#?}", command.join(" "));
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

/// Exports all slides (or one) from pdf to png.
pub fn export_slides<P: AsRef<Path>, Q: AsRef<Path>>(
    input: P,
    output: Q,
    page: Option<i32>,
) -> Result<String> {
    println!(
        "input = {:#?}, output = {:#?} ",
        input.as_ref().to_str().unwrap(),
        &format!("{}/", output.as_ref().to_str().unwrap())
    );

    match page {
        Some(x) => {
            let command_input_path = format!("{}[{}]", input.as_ref().to_str().unwrap(), x);
            let command_output_path = format!("{}/{:05}.png", output.as_ref().display(), x);
            let command = vec![
                "convert",
                "-density",
                "380",
                &command_input_path,
                "-colorspace",
                "sRGB",
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
            Ok(command_output_path)
        }

        None => {
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
                    "380",
                    &command_input_path,
                    "-colorspace",
                    "sRGB",
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

            Ok(output.as_ref().to_str().unwrap().to_string())
        }
    }
}

/// Video metadata strcuture
pub struct VideoMetadata {
    /// video with audio ?
    pub with_audio: bool,

    /// video duration
    pub duration: Option<f64>,
}

impl VideoMetadata {
    ///ffmpeg metaddata
    pub fn metadata<P: AsRef<Path>>(input_path: P) -> Result<VideoMetadata> {
        ffmpeg::init().unwrap();
        let mut video_metadata = VideoMetadata {
            with_audio: false,
            duration: None,
        };

        match ffmpeg::format::input(&input_path) {
            Ok(context) => {
                for (k, v) in context.metadata().iter() {
                    println!("{}: {}", k, v);
                }

                if let Some(stream) = context.streams().best(ffmpeg::media::Type::Video) {
                    println!("Best video stream index: {}", stream.index());
                }

                if let Some(stream) = context.streams().best(ffmpeg::media::Type::Audio) {
                    println!("Best audio stream index: {}", stream.index());
                    video_metadata.with_audio = true;
                } else {
                    println!("No audio found");
                }

                if let Some(stream) = context.streams().best(ffmpeg::media::Type::Subtitle) {
                    println!("Best subtitle stream index: {}", stream.index());
                }

                if context.duration() > 0 {
                    video_metadata.duration =
                        Some(context.duration() as f64 / f64::from(ffmpeg::ffi::AV_TIME_BASE));
                };

                println!(
                    "duration (seconds): {:.2}",
                    context.duration() as f64 / f64::from(ffmpeg::ffi::AV_TIME_BASE)
                );

                for stream in context.streams() {
                    println!("stream index {}:", stream.index());
                    println!("\ttime_base: {}", stream.time_base());
                    println!("\tstart_time: {}", stream.start_time());
                    println!("\tduration (stream timebase): {}", stream.duration());
                    println!(
                        "\tduration (seconds): {:.2}",
                        stream.duration() as f64 * f64::from(stream.time_base())
                    );
                    println!("\tframes: {}", stream.frames());
                    println!("\tdisposition: {:?}", stream.disposition());
                    println!("\tdiscard: {:?}", stream.discard());
                    println!("\trate: {}", stream.rate());

                    let codec = stream.codec();
                    println!("\tmedium: {:?}", codec.medium());
                    println!("\tid: {:?}", codec.id());

                    if codec.medium() == ffmpeg::media::Type::Video {
                        if let Ok(video) = codec.decoder().video() {
                            println!("\tbit_rate: {}", video.bit_rate());
                            println!("\tmax_rate: {}", video.max_bit_rate());
                            println!("\tdelay: {}", video.delay());
                            println!("\tvideo.width: {}", video.width());
                            println!("\tvideo.height: {}", video.height());
                            println!("\tvideo.format: {:?}", video.format());
                            println!("\tvideo.has_b_frames: {}", video.has_b_frames());
                            println!("\tvideo.aspect_ratio: {}", video.aspect_ratio());
                            println!("\tvideo.color_space: {:?}", video.color_space());
                            println!("\tvideo.color_range: {:?}", video.color_range());
                            println!("\tvideo.color_primaries: {:?}", video.color_primaries());
                            println!(
                                "\tvideo.color_transfer_characteristic: {:?}",
                                video.color_transfer_characteristic()
                            );
                            println!("\tvideo.chroma_location: {:?}", video.chroma_location());
                            println!("\tvideo.references: {}", video.references());
                            println!("\tvideo.intra_dc_precision: {}", video.intra_dc_precision());
                        }
                    } else if codec.medium() == ffmpeg::media::Type::Audio {
                        if let Ok(audio) = codec.decoder().audio() {
                            println!("\tbit_rate: {}", audio.bit_rate());
                            println!("\tmax_rate: {}", audio.max_bit_rate());
                            println!("\tdelay: {}", audio.delay());
                            println!("\taudio.rate: {}", audio.rate());
                            println!("\taudio.channels: {}", audio.channels());
                            println!("\taudio.format: {:?}", audio.format());
                            println!("\taudio.frames: {}", audio.frames());
                            println!("\taudio.align: {}", audio.align());
                            println!("\taudio.channel_layout: {:?}", audio.channel_layout());
                            println!("\taudio.frame_start: {:?}", audio.frame_start());
                        }
                    }
                }
            }

            Err(error) => println!("error: {}", error),
        }
        Ok(video_metadata)
    }
}
