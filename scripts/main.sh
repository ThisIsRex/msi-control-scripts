#!/bin/bash

set -eo pipefail

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Ошибка: Скрипт должен быть запущен с правами root!" >&2
        exit 1
    fi
}

load_ec() {
    if ! modprobe ec_sys write_support=1; then
        return 1
    fi
}

unload_ec() {
    modprobe -r ec_sys
}

write_ec() {
    local address_dec=$(($1))
    local value_dec=$(($2))
    local ec_path="/sys/kernel/debug/ec/ec0/io"
    
    echo -ne "\x$(printf '%02x' "$value_dec")" | dd of="$ec_path" bs=1 seek="$address_dec" conv=notrunc 2>/dev/null
}

send_notification() {
    local status="$1"
    local message="$2"
    message=$(sed 's/</\&lt;/g; s/>/\&gt;/g' <<< "$message")
    
    local user=${SUDO_USER:-$(logname)}
    local display=${DISPLAY:-":0"}
    local xauthority="/home/$user/.Xauthority"
    local dbus_address
    
    # Попытка получить DBUS адрес через стандартный сокет
    if [[ -S "/run/user/$(id -u "$user")/bus" ]]; then
        dbus_address="unix:path=/run/user/$(id -u "$user")/bus"
    else
        # Альтернативный метод через поиск в процессах
        local pid=$(pgrep -u "$user" -n -f "dbus-daemon --session" 2>/dev/null || true)
        if [[ -n "$pid" && -f "/proc/$pid/environ" ]]; then
            dbus_address=$(grep -z DBUS_SESSION_BUS_ADDRESS "/proc/$pid/environ" | tr -d '\0' | cut -d= -f2-)
        fi
    fi

    if [[ -z "$dbus_address" ]]; then
        echo "Не удалось определить DBUS_SESSION_BUS_ADDRESS. Уведомления не отправлены."
        return
    fi

    sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="$dbus_address" DISPLAY="$display" XAUTHORITY="$xauthority" \
        notify-send --app-name="$SCRIPT_NAME" "$status" "$message" 2>/dev/null || true
}

main() {
    check_root

    local arg_found=0
    local target_value=""
    local target_desc=""

    if [[ $# -gt 0 ]]; then
        for option in "${OPTIONS[@]}"; do
            IFS=':' read -r desc value cmd_arg <<< "$option"
            if [[ "$1" == "$cmd_arg" ]]; then
                target_value=$value
                target_desc=$desc
                arg_found=1
                break
            fi
        done
        [[ $arg_found -eq 0 ]] && { echo "Неизвестный аргумент: $1"; exit 1; }
    else
        echo "$SCRIPT_NAME"
        for i in "${!OPTIONS[@]}"; do
            IFS=':' read -r desc value cmd_arg <<< "${OPTIONS[$i]}"
            printf "%d. %s (%s)\n" $((i+1)) "$desc" "$cmd_arg"
        done

        read -p "Выберите действие [1-${#OPTIONS[@]}]: " choice
        [[ ! $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#OPTIONS[@]})) && { echo "Ошибка выбора"; exit 1; }

        IFS=':' read -r target_desc target_value cmd_arg <<< "${OPTIONS[$((choice-1))]}"
    fi

    if load_ec; then
        if write_ec $EC_ADDRESS $target_value; then
            send_notification "Успешно" "Адрес: ${EC_ADDRESS}, Значение: ${target_value} (${target_desc})"
        else
            send_notification "Ошибка" "Не удалось записать значение!"
            unload_ec
            exit 1
        fi
        unload_ec
    else
        send_notification "Ошибка" "Не удалось загрузить модуль ec_sys"
        exit 1
    fi
}