#!/usr/bin/env bash
# run this sript after the db migrations.
# remove all uneeed UUID in projects and caspules name

# Looks for the Rocket.toml and uses the database url in it to run diesel
# commands.

while [ ! -f Rocket.toml ]; do
    cd ..

    if [ "$PWD" == "/" ]; then
        echo -e >&2 "\033[31;1merror:\033[0m unable to find a Rocket.toml"
        exit 1
    fi
done

url=$(cat Rocket.toml | grep url | cut -d '"' -f 2)
python3  migrations/2020-09-15-081302_validate_capsule/clear_project_uuid.py $url
