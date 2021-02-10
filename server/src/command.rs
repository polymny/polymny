//! This module helps us to run commands.
use std::io;
use std::path::Path;
use std::process::{Command, Output};

use crate::config::Config;
use crate::{Error, Result};
use rayon::prelude::*;

extern crate ffmpeg_next as ffmpeg;

/// Runs a specified command.
pub fn run_command(command: &Vec<&str>) -> io::Result<Output> {
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

/// Counts the pages of a PDF file.
pub fn count_pages<P: AsRef<Path>>(input: P) -> Result<u32> {
    let output = run_command(&vec![
        "qpdf",
        "--show-pages",
        input.as_ref().to_str().unwrap(),
    ])?;

    let mut count = 0;

    for line in std::str::from_utf8(&output.stdout).unwrap().lines() {
        if line.starts_with("page") {
            count += 1;
        }
    }

    Ok(count)
}

/// Convert One pdf to One png
fn pdf2png(input: &str, output: &str, pdf_target_density: &str, pdf_target_size: &str) {
    let command = vec![
        "convert",
        "-density",
        &pdf_target_density,
        &input,
        "-colorspace",
        "sRGB",
        "-resize",
        &pdf_target_size,
        "-background",
        "white",
        "-gravity",
        "center",
        "-extent",
        &pdf_target_size,
        &output,
    ];
    run_command(&command).unwrap();
}
/// Exports all slides (or one) from pdf to png.
pub fn export_slides<P: AsRef<Path>, Q: AsRef<Path>>(
    config: &Config,
    input: P,
    output: Q,
    page: Option<i32>,
) -> Result<String> {
    let pdf_target_size = config.pdf_target_size.clone();
    let pdf_target_density = config.pdf_target_density.clone();
    match page {
        Some(x) => {
            let command_input_path = format!("{}[{}]", input.as_ref().to_str().unwrap(), x);
            let command_output_path = format!("{}/{:05}.png", output.as_ref().display(), x);
            pdf2png(
                &command_input_path,
                &command_output_path,
                &pdf_target_density.to_string(),
                &pdf_target_size.to_string(),
            );

            Ok(command_output_path)
        }

        None => {
            let vec: Vec<u32> = (0..count_pages(&input)?).collect();
            let vec_in = vec
                .iter()
                .map(|i| format!("{}[{}]", input.as_ref().to_str().unwrap(), i))
                .zip(
                    vec.iter()
                        .map(|i| format!("{}/{:05}.png", output.as_ref().to_str().unwrap(), i)),
                )
                .collect::<Vec<_>>();

            vec_in.par_iter().for_each(|(filepath, filepath_out)| {
                pdf2png(
                    filepath,
                    filepath_out,
                    &pdf_target_density,
                    &pdf_target_size,
                );
            });

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
    ///ffmpeg metadata
    pub fn metadata<P: AsRef<Path>>(input_path: P) -> Result<VideoMetadata> {
        ffmpeg::init().unwrap();
        let mut video_metadata = VideoMetadata {
            with_audio: false,
            duration: None,
        };

        match ffmpeg::format::input(&input_path) {
            Ok(context) => {
                if let Some(_stream) = context.streams().best(ffmpeg::media::Type::Audio) {
                    video_metadata.with_audio = true;
                }

                if context.duration() > 0 {
                    video_metadata.duration =
                        Some(context.duration() as f64 / f64::from(ffmpeg::ffi::AV_TIME_BASE));
                };
            }

            Err(error) => println!("error: {}", error),
        }
        Ok(video_metadata)
    }

    /// Dump metadata for a video
    pub fn dump_metadata<P: AsRef<Path>>(input_path: P) -> Result<VideoMetadata> {
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

/// Trancode blob in MP4 .
pub fn transcode_blob<P: AsRef<Path>, Q: AsRef<Path>>(input: P, output: Q) -> Result<f64> {
    let command = vec![
        "ffmpeg",
        "-hide_banner",
        "-y",
        "-i",
        input.as_ref().to_str().unwrap(),
        "-filter:v",
        "fps=fps=25",
        "-vsync",
        "cfr",
        "-vcodec",
        "libx264",
        "-crf",
        "15",
        "-acodec",
        "aac",
        output.as_ref().to_str().unwrap(),
    ];
    let child = run_command(&command)?;
    if !child.status.success() {
        return Err(Error::TranscodeError);
    }

    let metadata = VideoMetadata::metadata(&output)?;
    match metadata.duration {
        Some(x) => Ok(x),
        None => return Err(Error::TranscodeError),
    }
}

/// Extract audio from MP4 .
pub fn extract_audio<P: AsRef<Path>, Q: AsRef<Path>>(input: P, output: Q) -> Result<f64> {
    let command = vec![
        "ffmpeg",
        "-hide_banner",
        "-y",
        "-i",
        input.as_ref().to_str().unwrap(),
        "-map",
        "0:a",
        output.as_ref().to_str().unwrap(),
    ];
    let child = run_command(&command)?;
    if !child.status.success() {
        return Err(Error::TranscodeError);
    }

    let metadata = VideoMetadata::metadata(&output)?;
    match metadata.duration {
        Some(x) => Ok(x),
        None => return Err(Error::TranscodeError),
    }
}

/// Returns true if the path is a video that doesn't have only sound.
pub fn has_images<P: AsRef<Path>>(input: P) -> Result<bool> {
    let child = run_command(dbg!(&vec![
        "ffprobe",
        "-i",
        input.as_ref().to_str().unwrap(),
        "-show_streams",
        "-select_streams",
        "v",
        "-loglevel",
        "error"
    ]))?;
    println!("{:?}", child.stdout);
    Ok(!child.stdout.is_empty())
}
