#!/bin/bash
source "$(dirname "$0")/main.sh"

SCRIPT_NAME="Speaker Mute"
EC_ADDRESS=0x2D
OPTIONS=(
    "Включено:0x00:--on"
    "Отключено:0x02:--off"
)

main "$@"
