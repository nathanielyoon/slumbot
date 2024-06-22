#!/usr/bin/env bash
# set -x

api() {
    BODY=$(curl -s "https://slumbot.com/api/$1" \
        --header "Content-Type: application/json" \
        -d "$2")
    ACTION=$(jq '"b50b100" + .action' <<<"$BODY")
}
cards() {
    local array
    read -ra array <<<"$(jq -r "$1" <<<"$BODY")"
    for card in "${array[@]}"; do
        if [[ "$card" == null ]]; then
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
            A) code+="1" ;;
            2) code+="2" ;;
            3) code+="3" ;;
            4) code+="4" ;;
            5) code+="5" ;;
            6) code+="6" ;;
            7) code+="7" ;;
            8) code+="8" ;;
            9) code+="9" ;;
            T) code+="a" ;;
            J) code+="b" ;;
            Q) code+="d" ;;
            K) code+="e" ;;
            esac
            printf "\U%s " "$code"
        fi
    done
}
board() {
    local position
    position=$(jq -r 'if .client_pos == 0 then "><" else "<>" end' <<<"$BODY")
    printf "%s%s %s\n%-5s %s %s\n%s%s %s\n> " \
        "${position:0:1}" \
        "$(cards '(.bot_hole_cards // [null,null])[]')" \
        "$1" \
        "$2" \
        "$(cards '.board[range(5)]')" \
        "$3" \
        "${position:1:1}" \
        "$(cards '.hole_cards[]')" \
        "$4"
}
difference() {
    printf "%+d" "$(($1 - $(jq "$2" <<<"$BODY")))"
}

act() {
    local calls
    calls=$(jq '
    [match("b(\\d+)c"; "g") | .captures[0].string | tonumber]
    | add // 0
    | . * 2
' <<<"$ACTION")
    local bet1
    bet1=$(jq 'match("\\d+(?=b\\d+$)").string // "0" | tonumber' <<<"$ACTION")
    local bet2
    bet2=$(jq 'match("\\d+$").string // "0" | tonumber' <<<"$ACTION")
    local action
    action=$(jq -r 'match("([fkc]|(?<=b)\\d+)/?$").captures[0].string' <<<"$ACTION")
    local price=""
    case "$action" in
    f) local action="FOLD" ;;
    k) local action="CHECK" ;;
    c) local action="CALL" ;;
    *) local price="($((action - bet1)))" ;;
    esac
    board \
        "$action $price" \
        "$((calls + bet1 + bet2))" \
        "" \
        "$((20000 - calls / 2 - bet1))"
}

new_hand() {
    local winnings
    winnings=$(jq '.winnings' <<<"$BODY")
    local session
    session=$(jq '.session_total' <<<"$BODY")
    board \
        "$winnings $(difference "$winnings" '.baseline_winnings')" \
        "$(jq '.[-1:] |
    if . == "f" then "FOLD"
    elif . == "k" then "CHECK"
    elif . == "c" then "CALL"
    end
' <<<"$ACTION")" \
        "$(jq '.session_num_hands' <<<"$BODY")" \
        "$session $(difference "$session" '.session_baseline_total')"
}
main() {
    api new_hand {}
    TOKEN=$(jq -r '.token' <<<"$BODY")
    act
}

main

# PHOLE ACTION (PRICE)
# POT!! FFFFFFTTRR
# PHOLE CHIPS

# PHOLE WINNIN (DIFF)
# ACTIN FFFFFFTTRR HNDS
# PHOLE SESSIO (DIFF)
