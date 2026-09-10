#!/bin/bash

export LC_ALL=ru_RU.UTF-8

ALPHABET="АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
ALPHA_LEN=32
DEFAULT_TEXT="Старого воробья на мякине не проведёшь."

declare -A CHAR_TO_IDX
declare -A IDX_TO_CHAR

for ((i=0; i<ALPHA_LEN; i++)); do
    ch="${ALPHABET:$i:1}"
    CHAR_TO_IDX["$ch"]=$i
    IDX_TO_CHAR[$i]="$ch"
done

to_upper() {
    local text="${1^^}"
    text="${text//Ё/Е}"
    echo "$text"
}

preprocess() {
    local text
    text=$(to_upper "$1")
    text="${text//./ТЧК}"
    text="${text//,/ЗПТ}"
    text="${text//-/ТИРЕ}"
    text="${text// /}"
    echo "$text"
}

clear_screen() {
    echo -e '\033[2J\033[H'
}

restore_text() {
    local text="$1"
    text="${text//ТЧК/.}"
    text="${text//ЗПТ/,}"
    text="${text//ТИРЕ/-}"
    echo "$text"
}

format_output() {
    local text="$1"
    local len=${#text}
    local result=""
    local count=0
    local line_len=0
    for ((i=0; i<len; i+=5)); do
        local group="${text:$i:5}"
        if [[ -n "$result" ]]; then
            result+=" $group"
            line_len+=6
        else
            result="$group"
            line_len=${#group}
        fi
        count=$((count + 1))
        if [[ $count -ge 10 && $((i+5)) -lt $len ]]; then
            result+="
"
            count=0
            line_len=0
        fi
    done
    echo "$result"
}

get_idx() {
    echo "${CHAR_TO_IDX[$1]}"
}

get_char() {
    echo "${IDX_TO_CHAR[$1]}"
}

encrypt_atbash() {
    local text="$1"
    local len=${#text}
    local result=""
    for ((i=0; i<len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local new_idx=$((ALPHA_LEN - 1 - idx))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

decrypt_atbash() {
    encrypt_atbash "$1"
}

encrypt_trithemius() {
    local text="$1"
    local len=${#text}
    local result=""
    for ((i=0; i<len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local new_idx=$(( (idx + i) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

decrypt_trithemius() {
    local text="$1"
    local len=${#text}
    local result=""
    for ((i=0; i<len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local new_idx=$(( (idx - i + ALPHA_LEN) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

encrypt_belaso() {
    local text="$1"
    local key="$2"
    local key_len=${#key}
    local text_len=${#text}
    local result=""
    for ((i=0; i<text_len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local key_ch="${key:$((i % key_len)):1}"
        local key_idx=$(get_idx "$key_ch")
        local new_idx=$(( (idx + key_idx) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

decrypt_belaso() {
    local text="$1"
    local key="$2"
    local key_len=${#key}
    local text_len=${#text}
    local result=""
    for ((i=0; i<text_len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local key_ch="${key:$((i % key_len)):1}"
        local key_idx=$(get_idx "$key_ch")
        local new_idx=$(( (idx - key_idx + ALPHA_LEN) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

encrypt_vigenere_selfkey() {
    local text="$1"
    local key="$2"
    local text_len=${#text}
    local result=""
    for ((i=0; i<text_len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local key_ch=""
        if [[ $i -eq 0 ]]; then
            key_ch="$key"
        else
            key_ch="${text:$((i-1)):1}"
        fi
        local key_idx=$(get_idx "$key_ch")
        local new_idx=$(( (idx + key_idx) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

decrypt_vigenere_selfkey() {
    local text="$1"
    local key="$2"
    local text_len=${#text}
    local result=""
    for ((i=0; i<text_len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local key_ch=""
        if [[ $i -eq 0 ]]; then
            key_ch="$key"
        else
            key_ch="${result:$((i-1)):1}"
        fi
        local key_idx=$(get_idx "$key_ch")
        local new_idx=$(( (idx - key_idx + ALPHA_LEN) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

encrypt_vigenere_autotext() {
    local text="$1"
    local key="$2"
    local key_len=${#key}
    local text_len=${#text}
    local result=""
    for ((i=0; i<text_len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local key_ch=""
        if [[ $i -lt $key_len ]]; then
            key_ch="${key:$i:1}"
        else
            key_ch="${result:$((i - key_len)):1}"
        fi
        local key_idx=$(get_idx "$key_ch")
        local new_idx=$(( (idx + key_idx) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

decrypt_vigenere_autotext() {
    local text="$1"
    local key="$2"
    local key_len=${#key}
    local text_len=${#text}
    local result=""
    for ((i=0; i<text_len; i++)); do
        local ch="${text:$i:1}"
        local idx=$(get_idx "$ch")
        local key_ch=""
        if [[ $i -lt $key_len ]]; then
            key_ch="${key:$i:1}"
        else
            key_ch="${text:$((i - key_len)):1}"
        fi
        local key_idx=$(get_idx "$key_ch")
        local new_idx=$(( (idx - key_idx + ALPHA_LEN) % ALPHA_LEN ))
        result+=$(get_char $new_idx)
    done
    echo "$result"
}

main() {
    clear_screen
    while true; do
        echo "=== Шифровальщик ==="
        echo ""
        echo "1) Зашифровать"
        echo "2) Дешифровать"
        echo "3) Выход"
        read -p "Выберите режим (1-3): " mode
        clear_screen

        if [[ "$mode" == "3" ]]; then
            echo "До свидания!"
            exit 0
        fi

        if [[ "$mode" != "1" && "$mode" != "2" ]]; then
            echo "Ошибка: неверный режим"
            echo ""
            read -p "Нажмите Enter для продолжения..."
            clear_screen
            continue
        fi

        echo "Методы шифрования:"
        echo "1) Атбаш"
        echo "2) Шифр Тритемия"
        echo "3) Шифр Белазо"
        echo "4) Шифр Виженера с самоключом"
        echo "5) Шифр Виженера с ключом-шифртекстом"
        echo "6) Назад"
        read -p "Выберите метод (1-6): " method
        clear_screen

        if [[ "$method" == "6" ]]; then
            clear_screen
            continue
        fi

        if [[ "$method" != "1" && "$method" != "2" && "$method" != "3" && "$method" != "4" && "$method" != "5" ]]; then
            echo "Ошибка: неверный метод"
            echo ""
            read -p "Нажмите Enter для продолжения..."
            clear_screen
            continue
        fi

        read -p "Введите текст (Enter = фраза по умолчанию): " input_text
        clear_screen
        if [[ -z "$input_text" ]]; then
            input_text="$DEFAULT_TEXT"
        fi

        key=""
        if [[ "$method" == "3" || "$method" == "5" ]]; then
            while [[ -z "$key" ]]; do
                read -p "Введите ключ: " key
                clear_screen
                if [[ -z "$key" ]]; then
                    echo "Ошибка: ключ не может быть пустым"
                fi
            done
            key=$(preprocess "$key")
            for ((i=0; i<${#key}; i++)); do
                ch="${key:$i:1}"
                if [[ -z "${CHAR_TO_IDX[$ch]+x}" ]]; then
                    echo "Ошибка: ключ содержит недопустимые символы"
                    echo ""
                    read -p "Нажмите Enter для продолжения..."
                    clear_screen
                    continue 2
                fi
            done
        elif [[ "$method" == "4" ]]; then
            while [[ -z "$key" ]]; do
                read -p "Введите букву-ключ (одна буква): " key
                clear_screen
                if [[ -z "$key" ]]; then
                    echo "Ошибка: ключ не может быть пустым"
                elif [[ ${#key} -ne 1 ]]; then
                    echo "Ошибка: ключ должен быть одной буквой"
                    key=""
                else
                    key=$(to_upper "$key")
                    if [[ -z "${CHAR_TO_IDX[$key]+x}" ]]; then
                        echo "Ошибка: недопустимая буква"
                        key=""
                    fi
                fi
            done
        fi

        processed=$(preprocess "$input_text")

        if [[ ${#processed} -eq 0 ]]; then
            echo "Ошибка: текст не содержит допустимых символов"
            echo ""
            read -p "Нажмите Enter для продолжения..."
            clear_screen
            continue
        fi

        if [[ "$mode" == "1" ]]; then
            case "$method" in
                1) encrypted=$(encrypt_atbash "$processed") ;;
                2) encrypted=$(encrypt_trithemius "$processed") ;;
                3) encrypted=$(encrypt_belaso "$processed" "$key") ;;
                4) encrypted=$(encrypt_vigenere_selfkey "$processed" "$key") ;;
                5) encrypted=$(encrypt_vigenere_autotext "$processed" "$key") ;;
            esac
            echo "На вход:"
            echo "$input_text"
            echo ""
            echo "Зашифрованный:"
            format_output "$processed"
            format_output "$encrypted"
        else
            case "$method" in
                1) decrypted=$(decrypt_atbash "$processed") ;;
                2) decrypted=$(decrypt_trithemius "$processed") ;;
                3) decrypted=$(decrypt_belaso "$processed" "$key") ;;
                4) decrypted=$(decrypt_vigenere_selfkey "$processed" "$key") ;;
                5) decrypted=$(decrypt_vigenere_autotext "$processed" "$key") ;;
            esac
            echo "На вход:"
            echo "$input_text"
            echo ""
            echo "Зашифрованный:"
            format_output "$processed"
            echo ""
            echo "Расшифрованный:"
            restore_text "$decrypted"
        fi

        echo ""
        read -p "Нажмите Enter для продолжения..."
        clear_screen
    done
}

main
