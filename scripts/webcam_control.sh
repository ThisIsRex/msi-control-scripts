#!/bin/bash
source "$(dirname "$0")/main.sh"

SCRIPT_NAME="Web Cam Control"
EC_ADDRESS=0x2E
OPTIONS=(
    "Включено:0x0B:--on"
    "Отключено:0x09:--off"
)

main "$@"
