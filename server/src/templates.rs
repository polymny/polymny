//! This module contains the functions to render html.

use rocket_contrib::json::JsonValue;

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

/// Content of the test email in HTML format.
pub const TEST_EMAIL_HTML: &str =
    "<h1>Congratulations!</h1><p>If you received this email, it means that the mailer is working!</p>";

/// Content of the test email in text format.
pub const TEST_EMAIL_PLAIN_TEXT: &str =
    "Congratulations!\n\nIf you received this email, it means that the mailer is working!";

const INDEX_HTML_BEFORE_FLAGS: &str = r#"<!doctype HTML>
<html>
    <head>
        <meta charset="utf-8">

        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.7.2/css/all.css" integrity="sha384-fnmOCqbTlWIlj8LyTjo7mOUStjsKC4pOpQbqyi7RrhN7udi9RwhKkMHpvLbHG9Sr" crossorigin="anonymous">

    </head>
    <body>
        <div id="root"></div>
        <script src="/dist/main.js"></script>
        <script src="/dist/ports.js"></script>
        <script>
            var app = Elm.Main.init({
"#;

const INDEX_HTML_AFTER_FLAGS: &str = r#"
                node: document.getElementById('root')
            });
            setupPorts(app);
        </script>
    </body>
</html>
"#;

const SETUP_HTML: &str = r#"<!doctype HTML>
<html>
    <head>
        <title>Preparaption - Setup</title>
        <meta charset="utf-8">
    </head>
    <body>
        <div id="root"></div>
        <script src="/dist/setup.js"></script>
        <script>
            var app = Elm.Setup.init({
                node: document.getElementById('root')
            });
        </script>
    </body>
</html>
"#;

/// This functions formats the index.html page of the server from flags.
pub fn index_html(flags: Option<JsonValue>) -> String {
    let line = if let Some(flags) = flags {
        format!("flags: {},", flags.0)
    } else {
        "".to_string()
    };

    format!(
        "{}{}{}",
        INDEX_HTML_BEFORE_FLAGS, line, INDEX_HTML_AFTER_FLAGS
    )
}

/// This functions formats the setup.html page of the server.
pub fn setup_html() -> &'static str {
    SETUP_HTML
}
