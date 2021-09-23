fn main() {
    let args = std::env::args().skip(1).collect::<Vec<_>>();

    if args.len() != 2 {
        eprintln!("This program expects two arguments");
        std::process::exit(1);
    }

    match args[0].as_ref() {
        "encode" => {
            if let Ok(v) = args[1].parse::<i32>() {
                println!("{}", polymny::HARSH.encode(v));
            } else {
                eprintln!("{} is not an integer", args[1]);
                std::process::exit(1);
            }
        }
        "decode" => {
            if let Ok(v) = polymny::HARSH.decode(&args[1]) {
                println!("{}", v);
            } else {
                eprintln!("couldn't decode {}", args[1]);
                std::process::exit(1);
            }
        }
        x => {
            eprintln!("Command {} not recognized", x);
        }
    }
}
