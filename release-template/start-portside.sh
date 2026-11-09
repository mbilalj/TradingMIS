#!/usr/bin/env sh
cd "$(dirname "$0")" || exit 1
export SERVER_PORT="${SERVER_PORT:-8080}"
command -v java >/dev/null 2>&1 || { echo "Java 21+ is required (https://adoptium.net)"; exit 1; }
mkdir -p data
[ -f data/jwt.secret ] || head -c 48 /dev/urandom | od -An -tx1 | tr -d ' \n' > data/jwt.secret
export JWT_SECRET="$(cat data/jwt.secret)"
export SPRING_PROFILES_ACTIVE=standalone
echo "Starting Portside on http://localhost:$SERVER_PORT (Ctrl+C to stop)"
exec java -jar portside.jar
