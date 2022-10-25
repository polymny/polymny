#[rocket::main]
async fn main() -> Result<(), rocket::Error> {
    let _ = polymny::rocket().await?;
    Ok(())
}
