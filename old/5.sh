#!/usr/bin/env bash
# shellcheck disable=2034,2155

# - recent/final action should only show if the bot did it
# - handle error message
# - calculate bet sizes

HOST=https://slumbot.com/api
api() {
    BODY=$(curl -s "$HOST/$1" --header "Content-Type: application/json" -d "{\"token\":\"$TOKEN\"$2}")
    update
}
update() {
    ACTION=$(jq '"b50b100" + .action' <<<"$BODY")
    POT=$(jq '
    ([match("(?<=b)\\d+(?=c)"; "g").string | tonumber] | add // 0 | . * 2) +
    ([match("(?<=b)\\d+(?=b\\d+(?=$|f))"), match("(?<=b)\\d+(?=$|f)")] | map(.string | tonumber) | add // 0)
    | . / 10
' <<<"$ACTION")
}
cards() {
    for card in $1; do
        if [[ $card == null ]]; then
            printf "│  │"
        else
            case "${card:1:1}" in
            s) local suit=♤ ;;
            h) local suit=♡ ;;
            d) local suit=♢ ;;
            c) local suit=♧ ;;
            esac
            printf "│%s%s│" "${card:0:1}" "$suit"
        fi
    done
}
hand() {
    if [[ $2 == 0 ]]; then
        printf " ╭──╮╭──╮
 %s
 ╰──╯╰──╯" "$(cards "$1")"
    else
        printf " ╭──╮╭──╮ ╭───╮
 %s │BTN│
 ╰──╯╰──╯ ╰───╯" "$(cards "$1")"
    fi
}
board() {
    local position=$(jq '.client_pos' <<<"$BODY")
    printf "%s
%-10s┌────────────────────┐
%-10s│╭──╮╭──╮╭──╮╭──╮╭──╮│
%-10s│%s│
%-10s│╰──╯╰──╯╰──╯╰──╯╰──╯│
%-10s└────────────────────┘
%s
" \
        "$(hand "$(jq -r '(.bot_hole_cards // [null,null])[]' <<<"$BODY")" $((position ^ 1)))" \
        "$1" \
        "$2" \
        "$3" \
        "$(cards "$(jq -r '.board[range(5)]' <<<"$BODY")")" \
        "$4" \
        "$5" \
        "$(hand "$(jq -r '.hole_cards[]' <<<"$BODY")" "$position")"
}
act() {
    local action=$(jq -r 'match("(?:[kcf](?=/?$)|(?<=b)\\d+$)").string |
    if . == "k" then "check"
    elif . == "c" then "call"
    elif . == "f" then "fold"
    else . | tonumber | . / 10
end' <<<"$ACTION")
    board \
        "  $action" \
        "" \
        "  $POT" \
        "" \
        "> $(jq -r '
    if $action == "check" or $action == "call" then "0"
    elif $action == "fold" then "next"
    else match("(?<=b)\\d+(?=b\\d+$)").string | tonumber // 0 | . / 10
end' --arg action "$action" <<<"$ACTION")"
}
new_hand() {
    board \
        "  $(jq -r '.baseline_winnings / 10 | if . < 0 then . else "+\(.)" end' <<<"$BODY")" \
        "  $(jq -r '.session_baseline_total / 10 | if . < 0 then . else "+\(.)" end' <<<"$BODY")" \
        "$(jq -r 'match("[kcf]$").string |
    if . == "k" then "check"
    elif . == "c" then "call"
    else "fold"
end' <<<"$ACTION")" \
        "  $(jq -r '.winnings / 10 | if . < 0 then . else "+\(.)" end' <<<"$BODY")" \
        "  $(jq -r '.session_total / 10 | if . < 0 then . else "+\(.)" end' <<<"$BODY")"
}

incr() {
    printf ",\"incr\":\"%s\"" "$1"
}
input() {
    local key
    while true; do
        read -rsn1 key
        case $key in
        a) update new_hand ;;
        s) update act "$(incr f)" ;;
        d) update act "$(incr k)" ;;
        f) update act "$(incr c)" ;;
        j) update act "b min" ;;
        k) update act "b half" ;;
        l) update act "b full" ;;
        \;) update act "b all" ;;
        esac
    done
}
main() {
    BODY=$(curl -s "$HOST/new_hand" --header "Content-Type: application/json" -d {})
    TOKEN=$(jq -r '.token' <<<"$BODY")
    update
}

main
