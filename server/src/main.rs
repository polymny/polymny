#[rocket::main]
async fn main() -> Result<(), rocket::Error> {
    polymny::rocket().await
}
