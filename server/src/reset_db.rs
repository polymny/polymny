#[tokio::main]
async fn main() {
    polymny::reset_db().await;
}
