#!/usr/bin/env bash

set -euo pipefail

get_input() {
    local character=""
    local bet=""
    while true; do
        read -sn1 character
        case "$character" in
        j)
            echo f
            break
            ;;
        k)
            echo k
            break
            ;;
        l)
            echo "b$(($bet * 20))"
            break
            ;;
        \;)
            echo n
            break
            ;;
        $'\x1b')
            bet=""
            ;;
        0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9)
            bet+="$character"
            ;;
        esac
    done
}

card() {
    for card in "$@"; do
        if [[ "$card" == "?" ]]; then
            printf "\U1f0a0 "
        else
            local code=1f0
            case "${card:1:1}" in
            s) code+=a ;;
            h) code+=b ;;
            d) code+=c ;;
            c) code+=d ;;
            esac
            case "${card:0:1}" in
            A) code+=1 ;;
            2) code+=2 ;;
            3) code+=3 ;;
            4) code+=4 ;;
            5) code+=5 ;;
            6) code+=6 ;;
            7) code+=7 ;;
            8) code+=8 ;;
            9) code+=9 ;;
            T) code+=a ;;
            J) code+=b ;;
            Q) code+=d ;;
            K) code+=e ;;
            esac
            printf "\U$code "
        fi
    done
}

action() {
    local new=$(jq -r '.action' <<<$1)
    new=${new#"$(jq -r '.old_action' <<<$1)"}
    case $new in
    f | k | c) printf "  ${new#b}  " ;;
    *) printf "%-6s" $(jq '. / 10' <<<${new#b}) ;;
    esac
}
pot() {
    printf "%5s" $(jq '
    .action
    | [match("b(\\d+)(?:c|$)"; "g") | .captures[0].string | tonumber]
    | add // 0
    | . / 10
' <<<$1)
}
board() {
    card $(jq -r '[
    .board[0],
    .board[1],
    .board[2],
    .board[3] // "?",
    .board[4] // "?"
][]' <<<$1)
}
commitment() {
    case $1 in
    0)
        jq '
    .action
    | [match(""; "g") | .captures[0].string | tonumber]            
    | add // 0
    | . / 10
' <<<$2
        ;;
    1)
        echo BTN
        # jq '' <<<$2
        ;;
    esac
}

# $(card $(jq -r '(.bot_hole_cards // ["?","?"])[]' <<<$1))
display() {
    local position=$(jq '.client_pos' <<<$1)
    printf "$(action "$1")
$(pot "$1")  $(board "$1")
$position $(card $(jq -r '.hole_cards[]' <<<$1))"
}

main() {
    printf '\e[?25l\e[2J\e[H'
    display '{
    "old_action": "",
    "action": "b200",
    "client_pos": 0,
    "hole_cards": [
        "Jc",
        "2s"
    ],
    "board": ["5h", "4d", "3c"],
    "token": "1d0c0ff6-ff2b-40a3-83fa-3c893a797526"
}'
    sleep 2
    printf '\e[?25h\e[2B'
}
main

# ACTION IN!!! HOLE
# POT!!  FFFTR SSSSSS H#!!
# P HOLE IN!!! BASE!!
