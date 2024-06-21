#!/usr/bin/env bash
# shellcheck disable=2034,2155,2162

api() {
    RESPONSE=$(curl -s "https://slumbot.com/api/$1" --header content-type:\ application/json -d "$2")
    local message=$(jq -r '.error_msg // ""' <<<"$RESPONSE")
    if [[ -n $message ]]; then
        printf "%s\n" "$message"
    else
        BODY=$RESPONSE
    fi
}
api new_hand {}
TOKEN=$(jq -r '"\"token\":\"\(.token)\""' <<<"$BODY")
post() {
    if [[ -n $1 ]]; then
        api act "{$TOKEN,\"incr\":\"$1\"}"
    else
        api new_hand "{$TOKEN}"
    fi
}
DIFFERENCE="/ 10 | if . < 0 then . else \"+\(.)\" end else \"\" end"
difference() {
    local me=$(jq -r "if .$1 != null then .$1 $DIFFERENCE" <<<"$BODY")
    printf "\e[1E\e[10C%-4s \e[2m%s\e[0m" "$me" "$(jq -r "if .$2 != null then (\$me | tonumber) - .$2 $DIFFERENCE" --arg me "$me" <<<"$BODY")"
}
BUTTON="Ⓓ "
card() {
    if [[ -n $1 ]]; then
        case ${1:1:1} in
        s) printf "\e[30m%s♤\e[0m" "${1:0:1}" ;;
        h) printf "\e[31m%s♡\e[0m" "${1:0:1}" ;;
        d) printf "\e[34m%s♢\e[0m" "${1:0:1}" ;;
        c) printf "\e[32m%s♧\e[0m" "${1:0:1}" ;;
        esac
    else
        printf "  "
    fi
}

printf "\e[2J\e[H╭──╮╭──╮
│  ││  │
╰──╯╰──╯
>        ┌──────────────────────┐
┌──────┐ │ ╭──╮╭──╮╭──╮╭──╮╭──╮ │
│      │ │ │  ││  ││  ││  ││  │ │
└──────┘ │ ╰──╯╰──╯╰──╯╰──╯╰──╯ │
>        └──────────────────────┘
╭──╮╭──╮   
│  ││  │
╰──╯╰──╯
"
STATE=1
update() {
    local hands=$(jq -r '(.hole_cards // []) + (.bot_hole_cards // []) | join("")' <<<"$BODY")
    local board=$(jq -r '.board | join("")' <<<"$BODY")
    local position=$(jq '.client_pos' <<<"$BODY")
    local action=$(jq '"/b50b100" + .action' <<<"$BODY")
    local calls=$(jq '[match("(?<=b)\\d+(?=0c)"; "g").string | tonumber] | add // 0' <<<"$action")
    local act_1=$(jq -r 'match("/(?:[kcf]|b\\d+)(?:(?:[kcf]|b\\d+){2})*([kcf]|b\\d+?)0?(?:[kcf]|b\\d+)?$").captures[0].string' <<<"$action")
    local act_2=$(jq -r 'match("/(?:(?:[kcf]|b\\d+){2})*([kcf]|b\\d+?)0?(?:[kcf]|b\\d+)?$").captures[0].string' <<<"$action")
    local pot=$(jq '. * 2 + try ($act_1 | tonumber) catch 0 + try ($act_2 | tonumber) catch 0' --arg act_1 "${act_1#b}" --arg act_2 "${act_2#b}" <<<"$calls")
    printf "\e[H\e[9B\e[1C"
    card "${hands:0:2}"
    printf "\e[2C"
    card "${hands:2:2}"
    printf "\e[1C%s" "${BUTTON:$position:1}"
    printf "\e[8F\e[1C"
    card "${hands:4:2}"
    printf "\e[2C"
    card "${hands:6:2}"
    printf "\e[1C%s" "${BUTTON:$((position ^ 1)):1}"
    printf "\e[4E\e[2C%-4s\e[6C" "$pot"
    card "${board:0:2}"
    printf "\e[2C"
    card "${board:2:2}"
    printf "\e[2C"
    card "${board:4:2}"
    printf "\e[2C"
    card "${board:6:2}"
    printf "\e[2C"
    card "${board:8:2}"
    if [[ $position == 0 ]]; then
        printf "\e[2F\e[2C%-5s\e[4E\e[2C%-5s" "$act_2" "$act_1"
        local chips=$(jq '2000 - . - try ($act_1 | tonumber) catch 0' --arg act_1 "${act_1#b}" <<<"$calls")
    else
        printf "\e[2F\e[2C%-5s\e[4E\e[2C%-5s" "$act_1" "$act_2"
        local chips=$(jq '2000 - . - try ($act_2 | tonumber) catch 0' --arg act_2 "${act_2#b}" <<<"$calls")
    fi
    printf "\e[1E\e[10C%s" "$chips"
    difference "winnings" "baseline_winnings"
    difference "session_total" "session_baseline_total"
    printf "\e[H\e[12B"
}

main() {
    printf "\e[?25l"
    while true; do
        update
        read command
        post "$command"
    done
}

main
