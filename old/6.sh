#!/usr/bin/env bash
# shellcheck disable=2034,2155

BUTTON=" Ⓓ"
BODY=""
CHIPS=0
api() {
    RESPONSE=$(curl -s "https://slumbot.com/api/$1" --header "content-type: application/json" -d "$2")
    local message=$(jq -r '.error_msg // ""' <<<"$RESPONSE")
    if [[ -n $message ]]; then
        printf "%s\n" "$message"
    else
        BODY=$RESPONSE
    fi
}
api new_hand {}
TOKEN="\"token\":\"$(jq -r '.token' <<<"$BODY")\""
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
incr() {
    api act "{$TOKEN,\"incr\":\"$1\"}"
}
max() {
    jq "$1 | if . > \$chips then \$chips else . end | . * 10" --argjson chips "$CHIPS" <<<"$2"
}
main() {
    printf "\e[?25l"
    local position=0
    local action='""'
    local rounds="[]"
    local calls=0
    local pot=0
    local total=0
    local base_total=0
    local key=""
    while true; do
        local action=$(jq '"b50b100" + .action' <<<"$BODY")
        local position=$(jq '.client_pos' <<<"$BODY")
        local rounds=$(jq '
    (if $position == 0 then ["H", "V"] else ["V", "H"] end) as $order |
    [match("(\\w+)/?(\\w*)/?(\\w*)/?(\\w*)"; "g").captures[range(4)].string]
    | map([match("[fkc]|b\\d+"; "g").string])
    | to_entries
    | map(
        (if .key == 0 then 1 else 0 end) as $offset
        | .value
        | to_entries
        | map($order[(.key + $offset) % 2] + .value)
        | join("")
    )
' --argjson position "$position" <<<"$action")
        local calls=$(jq '[match("(?<=b)\\d+(?=0c)"; "g").string | tonumber] | add // 0' <<<"$action")
        local pot=$(jq '
    [match("(?<=b)\\d+(?=0b\\d+(?:$|f))").string, match("(?<=b)\\d+(?=0(?:$|f))").string]
    | map(tonumber)
    | (add // 0) + $calls * 2
' --argjson calls "$calls" <<<"$action")
        local previous=$(jq -r 'match("(?:[fkc]/?)+$|b\\d+(?=0$)").string' <<<"$action")
        CHIPS=$(jq '
    2000 -
    (match("\\d+(?=0b\\d+$)").string // "0" | tonumber)
    - $calls
' --argjson calls "$calls" <<<"$action")
        local total=$(jq '.session_total + $total' --argjson "total" "$total" <<<"$BODY")
        local base_total=$(jq '.session_baseline_total + $total' --argjson "total" "$base_total" <<<"$BODY")
        printf "╭──╮╭──╮
%s%s
╰──╯╰──╯
> %-4s   ┌──────────────────────┐
         │ ╭──╮╭──╮╭──╮╭──╮╭──╮ │
  \e[1m%-4s\e[0m   │ %s │
         │ ╰──╯╰──╯╰──╯╰──╯╰──╯ │
> %-4s   └──────────────────────┘
╭──╮╭──╮   \e[1m%s\e[0m
%s%s  %-6s \e[2m%s\e[0m
╰──╯╰──╯   %-6s \e[2m%s\e[0m
" \
            "$(cards "$(jq -r '(.bot_hole_cards // [null, null])[]' <<<"$BODY")")" \
            "${BUTTON:$((position ^ 1)):1}" \
            "$previous" \
            "$pot" \
            "$(cards "$(jq -r '(.board // [])[range(5)]' <<<"$BODY")")" \
            "$(jq -r 'match("(?:[fkc]|b\\d+?)(?=0?(?:[fkc]|b\\d+)$)").string' <<<"$action")" \
            "$CHIPS" \
            "$(cards "$(jq -r '.hole_cards[]' <<<"$BODY")")" \
            "${BUTTON:position:1}" \
            "$(jq -r '.winnings |
    if . == null then ""
    elif . > 0 then "+\(.)"
    else .
    end
' <<<"$BODY")" \
            "$(jq -r '.baseline_winnings |
    if . == null then ""
    elif . > 0 then "+\(.)"
    else .
    end
' <<<"$BODY")" \
            "$total" \
            "$base_total"
        read -rsn1 key
        case $key in
        a) api new_hand "{$TOKEN}" ;;
        s) incr f ;;
        d) incr k ;;
        f) incr c ;;
        j) incr "b$(max 'if .[0:1] == "b" then .[1:] | tonumber | . * 2 else 300 end' "\"$previous\"")" ;;
        k) incr "b$(max '. / 2' "$pot")" ;;
        l) incr "b$(max '.' "$pot")" ;;
        \;) incr "b$((CHIPS * 10))" ;;
        q)
            printf "\e[2J\e[H\e[?25h"
            exit
            ;;
        esac
        printf "\e[2J\e[H"
    done
}

main
