#!/usr/bin/env bash
# Sirve una carpeta por HTTP en la red local para descargar fotos desde Safari en el iPad.
# Uso: ./enviar.sh [carpeta] [puerto]

set -euo pipefail

DIR="${1:-$HOME/Pictures/Enviar}"
PORT="${2:-8000}"

if [[ ! -d "$DIR" ]]; then
    echo "La carpeta no existe: $DIR" >&2
    exit 1
fi

echo "Sirviendo: $DIR"
echo "Abre en Safari del iPad una de estas direcciones:"
for ip in $(hostname -I); do
    [[ "$ip" == *:* ]] && continue
    echo "  http://$ip:$PORT"
done
echo "Mantén presionada la foto y elige 'Guardar imagen'."
echo "Cierra el servidor con Ctrl+C cuando termines."
echo

exec python3 -m http.server "$PORT" --directory "$DIR"
