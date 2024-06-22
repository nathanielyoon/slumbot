#!/usr/bin/env bash

set -euo pipefail

START="\e[0G\e[3A\e[0J"
END="\n> "
fetch() {
    curl -s "https://slumbot.com/api/$1" \
        --header "Content-Type: application/json" \
        -d ${2:-"{\"token\":\"$TOKEN\"}"}
}
cards() {
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
board() {
    cards $(jq -r '.board | [
    .[0] // "?",
    .[1] // "?",
    .[2] // "?",
    .[3] // "?",
    .[4] // "?"
][]' <<<$1)
}
difference() {
    jq -r 'if . == 0 then " 0" elif . > 0 then "+\(.)" else . end'
}
act() {
    local position=$(jq '.client_pos' <<<$1)
    local action=$(jq '"b50b100" + .action' <<<$1)
    local calls=$(jq '
        [match("b(\\d+)c"; "g"), match("(\\d+)b\\d+$")]
        | map(.captures[0].string | tonumber)
        | add // 0
        | . / 10
' <<<$action)
    printf "$START\e[2m$((position ^ 1))\e[0m $(cards ? ?) $(($calls + $(jq '
    match("b(\\d+)$").captures[0].string
    | tonumber // 0
    | . / 10
' <<<$action)))
$(printf %-6s "$(jq -r 'match("^(?:[kcb/]\\d*)*([kc]|b\\d+)/?$").captures[0].string |
    if . == "k" then "CHECK"
    elif . == "c" then "CALL"
    else .[1:] | tonumber // 0 | . / 10
    end
' <<<$action)") $(board "$1")
\e[2m$position\e[0m $(cards $(jq -r '.hole_cards[]' <<<$1)) $((2000 - $calls))$END"
    local previous=$(jq 'match(".+(\\d+)").captures[0].string | tonumber | . * 2' <<<$action)
    local key=""
    local bet=""
    while true; do
        read -sn1 key
        case "$key" in
        0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9)
            bet+="$key"
            printf "$key"
            ;;
        $'\x1b')
            bet=""
            printf "\e[0G> \e[0K"
            ;;
        j)
            key=f
            break
            ;;
        k) break ;;
        l)
            key=c
            break
            ;;
        \;)
            key="b$(($bet < $previous ? $previous : $bet))"
            break
            ;;
        " ") break ;;
        esac
    done
    if [[ "$key" == " " ]]; then
        handle new_hand
    else
        handle act "{\"token\":\"$TOKEN\",\"incr\":\"$key\"}"
    fi
}
new() {
    local position=$(jq '.client_pos' <<<$1)
    printf "$START\e[2m$((position ^ 1))\e[0m $(cards $(jq -r '.bot_hole_cards[]' <<<$1)) $(printf %6s $(jq '.session_total' <<<$1)) \e[2m$(jq '.session_total - .session_baseline_total' <<<$1 | difference)\e[0m
$(jq -r '.action | match("([kcf])/?$").captures[0].string |
    if . == "k" then "CHECK "
    elif . == "c" then "CALL  "
    elif . == "f" then "FOLD  "
    end' <<<$1) $(board "$1") 
\e[2m$position\e[0m $(cards $(jq -r '.hole_cards[]' <<<$1)) $(printf %6s $(jq '.winnings' <<<$1)) \e[2m$(jq '.winnings - .baseline_winnings' <<<$1 | difference)\e[0m$END"
    local key
    while true; do
        read -sn1 key
        if [[ $key == " " ]]; then
            printf "$key"
            handle new_hand "{\"token\":\"$TOKEN\"}"
            break
        fi
    done
}
handle() {
    BODY="$(fetch $1 $2)"
    case "$(jq -r '.action[-1:]' <<<$BODY)" in
    c | f) new "$BODY" ;;
    *) act "$BODY" ;;
    esac
}

main() {
    BODY=$(fetch new_hand {})
    TOKEN=$(jq -r '.token' <<<$BODY)
    printf "\e[2J\e[H"
    act "$BODY"
    printf "\e[3B"
}

main
