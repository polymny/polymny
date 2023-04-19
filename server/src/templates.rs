//! This module contains the functions to render html.

use rocket::serde::json::Value;

/// This function formats a validation email with HTML format from an activation url.
pub fn validation_email_html(activaion_url: &str) -> String {
    format!(
        "<h1>Welcome</h1><a href=\"{}\">Click here to activate your account</a>",
        activaion_url
    )
}

/// This function formats a validation email with plain text format from an activation url.
pub fn validation_email_plain_text(activation_url: &str) -> String {
    format!(
        "Welcome!\n\nTo activate your account, please go to the following link:\n{}",
        activation_url
    )
}
/// This function formats a validation for email change with HTML format from an activation url.
pub fn validation_new_email_html(activaion_url: &str) -> String {
    format!(
        "<h1>Welcome</h1><a href=\"{}\">Click here to activate your new email</a>",
        activaion_url
    )
}

/// This function formats a validation for email change with plain text format from an activation url.
pub fn validation_new_email_plain_text(activation_url: &str) -> String {
    format!(
        "Welcome!\n\nTo activate your new email, please go to the following link:\n{}",
        activation_url
    )
}

/// This function formats a validation for polymny invitation with HTML format from an activation url.
pub fn validation_invitation_html(activaion_url: &str) -> String {
    format!(
        "<h1>Welcome</h1><a href=\"{}\">Click here to activate your invitation to join Polymny Studio </a>",
        activaion_url
    )
}

/// This function formats a validation for polymny invitation nwith plain text format from an activation url.
pub fn validation_invitation_plain_text(activation_url: &str) -> String {
    format!(
        "Welcome!\n\nTo activate your invitation to Polymny Studio, please go to the following link:\n{}",
        activation_url
    )
}

/// This function formats a reset password email with HTML format from a reset url.
pub fn reset_password_email_html(url: &str) -> String {
    format!(
        "<h1>You've recently request to change your password</h1><p><a href=\"{}\">Click here to change your password</a></p><p>If you haven not requested to change your password, you can ignore this email</p>",
        url
    )
}

/// This function formats a reset password email with plain text format from a reset url.
pub fn reset_password_email_plain_text(url: &str) -> String {
    format!(
        "You've recently request to change your password\n\nGo on the following link to change your password:\n{}\n\nIf you haven not requested to change your password, you can ignore this email</p>",
        url
    )
}

/// Content of the test email in HTML format.
pub const TEST_EMAIL_HTML: &str =
    "<h1>Congratulations!</h1><p>If you received this email, it means that the mailer is working!</p>";

/// Content of the test email in text format.
pub const TEST_EMAIL_PLAIN_TEXT: &str =
    "Congratulations!\n\nIf you received this email, it means that the mailer is working!";

#[cfg(debug_assertions)]
const INDEX_HTML_BEFORE_FLAGS: &str = r#"<!doctype HTML>
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="icon" type="image/png" href="/dist/favicon.ico"/>
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.7.2/css/all.css" integrity="sha384-fnmOCqbTlWIlj8LyTjo7mOUStjsKC4pOpQbqyi7RrhN7udi9RwhKkMHpvLbHG9Sr" crossorigin="anonymous">
        <style>
            .blink {
                animation: blinker 1s linear infinite;
            }

            @keyframes blinker {
                50% {
                    opacity: 0;
                }
            }

            @font-face {
                font-family: "Urbanist";
                src: url("/dist/fonts/Urbanist-Regular.woff2");
            }

            @font-face {
                font-family: "Urbanist";
                font-weight: bold;
                src: url("/dist/fonts/Urbanist-Bold.woff2");
            }
        </style>
    </head>
    <body>
        <div id="root"></div>
        <script src="/dist/js/main.js"></script>
        <script src="/dist/js/ports.js"></script>
        <script src="/dist/js/old-main.js"></script>
        <script src="/dist/js/old-ports.js"></script>
        <script src="/dist/jszip.min.js"></script>
        <script>
            var flags = "#;

#[cfg(not(debug_assertions))]
const INDEX_HTML_BEFORE_FLAGS: &str = r#"<!doctype HTML>
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="icon" type="image/png" href="/dist/favicon.ico"/>
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.7.2/css/all.css" integrity="sha384-fnmOCqbTlWIlj8LyTjo7mOUStjsKC4pOpQbqyi7RrhN7udi9RwhKkMHpvLbHG9Sr" crossorigin="anonymous">
        <style>
            .blink {
                animation: blinker 1s linear infinite;
            }

            @keyframes blinker {
                50% {
                    opacity: 0;
                }
            }

            @font-face {
                font-family: "Urbanist";
                src: url("/dist/fonts/Urbanist-Regular.woff2");
            }

            @font-face {
                font-family: "Urbanist";
                font-weight: bold;
                src: url("/dist/fonts/Urbanist-Bold.woff2");
            }
        </style>
    </head>
    <body>
        <div id="root"></div>
        <script src="/dist/js/main.min.js"></script>
        <script src="/dist/js/ports.js"></script>
        <script src="/dist/js/old-main.min.js"></script>
        <script src="/dist/js/old-ports.js"></script>
        <script src="/dist/jszip.min.js"></script>
        <script>
            var flags = "#;

const INDEX_HTML_AFTER_FLAGS: &str = r#";
            if (window.location.pathname.startsWith('/o')) {
                // Fix old flags case and load old client

                flags.global = flags.global.serverConfig || {};
                flags.global.socket_root = flags.global.socketRoot;
                flags.global.video_root = flags.global.videoRoot;
                flags.global.registration_disabled = flags.global.registrationDisabled;
                flags.global.request_language = flags.global.requestLanguage;

                flags.global.width = window.innerWidth;
                flags.global.height = window.innerHeight;
                flags.global.storage_language = localStorage.getItem('language');
                flags.global.acquisitionInverted = localStorage.getItem('acquisitionInverted') === "true";
                flags.global.zoomLevel = parseInt(localStorage.getItem('zoomLevel'), 10);
                if (isNaN(flags.global.zoomLevel)) {
                    flags.global.zoomLevel = null;
                }
                flags.global.videoDeviceId = localStorage.getItem('videoDeviceId');
                flags.global.audioDeviceId = localStorage.getItem('audioDeviceId');
                flags.global.resolution = localStorage.getItem('resolution');
                flags.global.sortBy = JSON.parse(localStorage.getItem('sortBy')) || ["lastModified", false];
                flags.global.promptSize = parseInt(localStorage.getItem('promptSize'), 10) || 25;
                var app = Elm.OldMain.init({
                    flags: flags,
                    node: document.getElementById('root')
                });
                setupPorts(app);
            } else {
               init(document.getElementById('root'), flags);
            }
        </script>
    </body>
</html>
"#;

#[cfg(debug_assertions)]
const SETUP_HTML: &str = r#"<!doctype HTML>
<html>
    <head>
        <title>Preparaption - Setup</title>
        <link rel="icon" href="/dist/favicon.ico"/>
        <meta charset="utf-8">
    </head>
    <body>
        <div id="root"></div>
        <script src="/dist/js/setup.js"></script>
        <script>
            var app = Elm.Setup.init({
                node: document.getElementById('root')
            });
        </script>
    </body>
</html>
"#;

#[cfg(not(debug_assertions))]
const SETUP_HTML: &str = r#"<!doctype HTML>
<html>
    <head>
        <title>Preparaption - Setup</title>
        <link rel="icon" href="/dist/favicon.ico"/>
        <meta charset="utf-8">
    </head>
    <body>
        <div id="root"></div>
        <script src="/dist/js/setup.min.js"></script>
        <script>
            var app = Elm.Setup.init({
                node: document.getElementById('root')
            });
        </script>
    </body>
</html>
"#;

/// This functions formats the index.html page of the server from flags.
pub fn index_html(flags: Value) -> String {
    format!(
        "{}{}{}",
        INDEX_HTML_BEFORE_FLAGS, flags, INDEX_HTML_AFTER_FLAGS
    )
}

/// This functions formats the setup.html page of the server.
pub fn setup_html() -> &'static str {
    SETUP_HTML
}

/// The HTML page that shows a video.
pub fn video_html(url: &str) -> String {
    format!(
        r#"<!doctype HTML>
<html>
    <head>
        <title>video.polymny.studio</title>
        <meta charset="utf-8">
    </head>
    <body>
        <div id="container"></div>
        <script src="/v/polymny-video-full.min.js"></script>
        <script>
            PolymnyVideo.fullpage({{
                node: document.getElementById("container"),
                url: "{}",
                autoplay: PolymnyVideo.getArgumentFromUrl("a") !== null,
                startTime: PolymnyVideo.getArgumentFromUrl("t"),
                enableMiniatures: true,
                muted: PolymnyVideo.getArgumentFromUrl("m") !== null
            }});
        </script>
    </body>
</html>
"#,
        url
    )
}
