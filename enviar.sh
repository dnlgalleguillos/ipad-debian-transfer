#!/usr/bin/env bash
# Serve a folder over HTTP on the local network so photos can be downloaded from Safari on the iPad.
# Usage: ./enviar.sh [folder] [port]

set -euo pipefail

DIR="${1:-$HOME/Pictures/Enviar}"
PORT="${2:-8000}"

if [[ ! -d "$DIR" ]]; then
    echo "Folder does not exist: $DIR" >&2
    exit 1
fi

echo "Serving: $DIR"
echo "Open one of these addresses in Safari on the iPad:"
for ip in $(hostname -I); do
    [[ "$ip" == *:* ]] && continue
    echo "  http://$ip:$PORT"
done
echo "Long-press the photo and choose 'Save Image'."
echo "Stop the server with Ctrl+C when you are done."
echo

exec python3 -m http.server "$PORT" --directory "$DIR"
