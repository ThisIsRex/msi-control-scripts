#!/bin/bash
source "$(dirname "$0")/main.sh"

SCRIPT_NAME="Performance Mode"
EC_ADDRESS=0xD2
OPTIONS=(
    "Экономия заряда:0xC2:--pws"
    "Сбалансированный:0xC1:--bal"
    "Производительность:0xC4:--prf"
)

main "$@"
