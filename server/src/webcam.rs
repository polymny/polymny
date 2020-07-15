//! This mmodules contains data type for Webcam manipulations
//!

/// Size of webcam view
#[derive(Serialize, Deserialize, Debug)]
pub enum WebcamSize {
    /// Small webcam view
    Small,

    /// Medium webcam view
    Medium,

    /// Large webcam view
    Large,
}

/// Position of webc&m view
#[derive(Serialize, Deserialize, Debug)]
pub enum WebcamPosition {
    /// Webcam view on the top, left of the slide
    TopLeft,

    /// Webcam view on the top, right of the slide
    TopRight,

    /// Webcam view on the bottome left of the slide
    BottomLeft,

    /// Webcam view on the  bottome right of the slide
    BottomRight,
}

/// Convert string to WebcamSize enum
pub fn str_to_webcam_size(string: &String) -> WebcamSize {
    match &string as &str {
        "Small" => WebcamSize::Small,
        "Medium" => WebcamSize::Medium,
        "Large" => WebcamSize::Large,
        _ => WebcamSize::Medium,
    }
}

/// Convert WebcamSize enum to String
pub fn webcam_size_to_str(webcam_size: WebcamSize) -> String {
    match webcam_size {
        WebcamSize::Small => "Small".into(),
        WebcamSize::Medium => "Medium".into(),
        WebcamSize::Large => "Large".into(),
    }
}

/// Convert string to WebcamPosition
pub fn str_to_webcam_position(string: &String) -> WebcamPosition {
    match &string as &str {
        "TopLeft" => WebcamPosition::TopLeft,
        "TopRight" => WebcamPosition::TopRight,
        "BottomLeft" => WebcamPosition::BottomLeft,
        "BottomRight" => WebcamPosition::BottomRight,
        _ => WebcamPosition::BottomLeft,
    }
}

/// Convert WebcamPosition enum to String
pub fn webcam_position_to_str(webcam_position: WebcamPosition) -> String {
    match webcam_position {
        WebcamPosition::TopLeft => "TopLeft".into(),
        WebcamPosition::TopRight => "TopRight".into(),
        WebcamPosition::BottomLeft => "BottomLeft".into(),
        WebcamPosition::BottomRight => "BottomRight".into(),
    }
}

/// Return WebcamSize in pixels
pub fn size_in_pixels(webcam_size: WebcamSize) -> String {
    match webcam_size {
        WebcamSize::Small => "200".to_string(),
        WebcamSize::Medium => "400".to_string(),
        WebcamSize::Large => "800".to_string(),
    }
}

/// Return WebcamPosition in Pixesls (for overlay filter in ffmpeg)
pub fn position_in_pixels(webcam_position: WebcamPosition) -> String {
    match webcam_position {
        WebcamPosition::TopLeft => "4:4".to_string(),
        WebcamPosition::TopRight => "W-w-4:4".to_string(),
        WebcamPosition::BottomLeft => "4:H-h-4".to_string(),
        WebcamPosition::BottomRight => "W-w-4:H-h-4".to_string(),
    }
}

/// Set of Webcam view options
#[derive(Serialize, Deserialize, Debug)]
pub struct EditionOptions {
    /// Only audio, or audio + video option
    pub with_video: bool,

    /// Size of webcam view
    pub webcam_size: WebcamSize,

    /// Position of webcam view in slide
    pub webcam_position: WebcamPosition,
}
