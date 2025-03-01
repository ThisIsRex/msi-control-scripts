#!/bin/bash
source "$(dirname "$0")/main.sh"

SCRIPT_NAME="Battery Charge Threshold"
EC_ADDRESS=0xD7
OPTIONS=(
    "100%:0xE4:--max"
    "Старт <70%, стоп >=80%:0xD0:--med"
    "Старт <50%, стоп >=60%:0xBC:--min"
)

main "$@"
