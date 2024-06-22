#!/usr/bin/env bash
set -euo pipefail

api() {
    # BODY=$(curl -s "https://slumbot.com/api/$1" --header "Content-Type: application/json" -d "$2")
    BODY='{
    "old_action": "b200c/kb200c/",
    "action": "b200c/kb200c/b400f",
    "client_pos": 0,
    "hole_cards": [
        "Ac",
        "8d"
    ],
    "board": [
        "Ks",
        "Ts",
        "4h",
        "6d"
    ],
    "bot_hole_cards": [
        "Jc",
        "3s"
    ],
    "winnings": 400,
    "won_pot": 1200,
    "session_num_hands": 13,
    "baseline_winnings": 800,
    "session_total": -800,
    "session_baseline_total": 600
}'
    ACTION=$(jq '"b50b100" + .action' <<<$BODY)
}
cards() {
    for card in "$@"; do
        if [[ "$card" == null ]]; then
            printf "\U1f0a0 "
        else
            local code=1f0
            case "${card:1:1}" in
            s) local code+=a ;;
            h) local code+=b ;;
            d) local code+=c ;;
            c) local code+=d ;;
            esac
            case "${card:0:1}" in
            A) local code+=1 ;;
            2) local code+=2 ;;
            3) local code+=3 ;;
            4) local code+=4 ;;
            5) local code+=5 ;;
            6) local code+=6 ;;
            7) local code+=7 ;;
            8) local code+=8 ;;
            9) local code+=9 ;;
            T) local code+=a ;;
            J) local code+=b ;;
            Q) local code+=d ;;
            K) local code+=e ;;
            esac
            printf "\U$code "
        fi
    done
}
board() {
    local position=$(jq -r 'if .client_pos == 0 then "DB" else "BD" end' <<<$BODY)
    printf "BPOS: ${position:0:1}\n"
    printf "MPOS: ${position:1:1}\n"

    printf "BHOL: $(cards $(jq -r '(.bot_hole_cards // [null,null])[]' <<<$BODY))\n"
    printf "MHOL: $(cards $(jq -r '.hole_cards[]' <<<$BODY))\n"
    printf "BORD: $(cards $(jq -r '.board[range(5)]' <<<$BODY))\n"
}
difference() {
    printf "%+d" "$(($1 - $(jq $2 <<<$BODY)))"
}
# PHOLE ACTION
# POT!! FFFFFFTTRR
# PHOLE PRICE!
act() {
    local calls=$(jq '
    [match("b(\\d+)c"; "g") | .captures[0].string | tonumber]
    | add // 0
    | . * 2
' <<<$ACTION)
    local bet=$(jq 'match("\\d+(?=b\\d+$)").string // "0" | tonumber' <<<$ACTION)
    local action=$(jq -r 'match("([fkc]|(?<=b)\\d+)/?$").captures[0].string' <<<$ACTION)
    case "$action" in
    f | k | c) local price="" ;;
    *) local price=$(($action - $bet)) ;;
    esac
    printf "POT!: $(($calls + $(jq 'match("\\d+$").string // "0" | tonumber' <<<$ACTION) + $bet))\n"
    printf "ACTN: $action\n"
    printf "PRIC: $price\n"
}
#
#
#
new_hand() {
    local winnings=$(jq '.winnings' <<<$BODY)
    printf "WINS: $winnings\n"
    printf "OVER: $(difference $winnings '.baseline_winnings')\n"

    local session=$(jq '.session_total' <<<$BODY)
    printf "SESS: $session\n"
    printf "BLWS: $(difference $session '.session_baseline_total')\n"

    printf "HAND: $(jq '.session_num_hands' <<<$BODY)\n"
}
main() {
    api new_hand {}
    TOKEN=$(jq -r '.token' <<<$BODY)
    board
}
main
