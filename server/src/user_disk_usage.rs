#[tokio::main]
async fn main() {
    polymny::user_disk_usage().await;
}
