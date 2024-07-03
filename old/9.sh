#!/usr/bin/env bash
# shellcheck disable=2034,2155,2162,2317

trap 'printf "\e[10;0f\e[0K\e[?25h"' 0
BUTTON="Ⓓ "
REGEX='"action":\s*"([/0-9fkcb]*)",\s*"client_pos":\s*([01]),\s*"hole_cards":\s*\[\s*"([2-9TJQKA][shdc])",\s*"([2-9TJQKA][shdc])"\s*\],\s*"board":\s*\[[[:space:]"]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]"]*\],?(\s*"bot_hole_cards":\s*\[\s*"([2-9TJQKA][shdc])",\s*"([2-9TJQKA][shdc])"\s*\],\s*"winnings":\s*(-?[0-9]+),\s*"won_pot":\s*-?[0-9]+,\s*"session_num_hands":\s*(-?[0-9]+),\s*"baseline_winnings":\s*(-?[0-9]+),\s*"session_total":\s*(-?[0-9]+),\s*"session_baseline_total":\s*(-?[0-9]+))?'
ERROR='"error_msg":\s*"([[:print:]]+?)"'
RECENT='([/kc]|b[0-9]+)([/kc]|b[0-9]+)([/fkc]|b[0-9]+)$'
CALLED='b([0-9]+)ck?/'
UNCALLED='([0-9]+)?b([0-9]+)f?$'
cards() {
    for argument; do
        if [[ -n $argument ]]; then
            case ${argument:1:1} in
            s) local suit="0♤" ;;
            h) local suit="1♡" ;;
            d) local suit="4♢" ;;
            c) local suit="2♧" ;;
            esac
            printf "\e[3%sm%s%s\e[0m\e[2C" "${suit:0:1}" "${argument:0:1}" "${suit:1:1}"
        else
            printf "  \e[2C"
        fi
    done
}
api() {
    curl -s "https://slumbot.com/api/$1" -H content-type:\ application/json -d "{$2}"
}
auto() {
    VALUE_1=${1:0:1}
    VALUE_2=${2:0:1}
    if [[ "$VALUE_1" == "$VALUE_2" ]]; then return 1; fi
    if [[ "${1:1:1}" == "${2:1:1}" ]]; then
        case $VALUE_1 in
        A | K) return 1 ;;
        Q | J)
            case $VALUE_2 in
            J | T | 9 | 8) return 1 ;;
            esac
            ;;
        T)
            case $VALUE_2 in
            9 | 8) return 1 ;;
            esac
            ;;
        *) if [[ $((VALUE_1 - VALUE_2)) -lt 3 ]]; then return 1; fi ;;
        esac
    else
        case $VALUE_1 in
        A)
            case $VALUE_2 in
            K | Q | J | T | 9) return 1 ;;
            esac
            ;;
        K | Q | J)
            case $VALUE_2 in
            Q | J | T) return 1 ;;
            esac
            ;;
        esac
    fi
    return 0
}
printf "\e[?25l\e[2J\e[H╭──╮╭──╮
│  ││  │
╰──╯╰──╯
┌──────┐  ╭──╮╭──╮╭──╮╭──╮╭──╮
│      │  │  ││  ││  ││  ││  │
└──────┘  ╰──╯╰──╯╰──╯╰──╯╰──╯
╭──╮╭──╮
│  ││  │
╰──╯╰──╯"
while getopts :p:a flag; do
    case $flag in
    p) printf "\e[11;0f%s" "$(<"$OPTARG")" ;;
    a) AUTO=yes ;;
    *) exit 1 ;;
    esac
done
BODY=$(api new_hand)
TOKEN="\"token\":\"${BODY: -38:36}\""
while true; do
    printf "\e[10;0f\e[0K"
    if [[ $BODY =~ $REGEX ]]; then
        if [[ $AUTO == yes ]] && auto "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; then
            printf "\e[8;2f"
            cards "" ""
            printf "\e[5;2f      \e[4C"
            cards "" "" "" "" ""
            printf "\e[2;2f"
            cards "" ""
            printf "\e[1;9f\e[0K\e[2;9f\e[0K\e[3;9f\e[0K\e[7;9f\e[0K\e[8;9f\e[0K\e[9;9f\e[0K"
            api act "$TOKEN,\"incr\":\"f\"" >/dev/null
            BODY=$(api new_hand "$TOKEN")
            continue
        fi
        POSITION=${BASH_REMATCH[2]}
        printf "\e[2;9f%s\e[8;9f%s\e[8;2f" "${BUTTON:$POSITION:1}" "${BUTTON:$((POSITION ^ 1)):1}"
        cards "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"
        printf "\e[5;12f"
        cards "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" "${BASH_REMATCH[7]}" "${BASH_REMATCH[8]}" "${BASH_REMATCH[9]}"
        printf "\e[2;2f"
        cards "${BASH_REMATCH[11]}" "${BASH_REMATCH[12]}"
        if [[ ${BASH_REMATCH[10]} ]]; then
            RESULT=$((BASH_REMATCH[13] / 10))
            RESULT_GAP=$((RESULT - BASH_REMATCH[15] / 10))
            [[ ${RESULT:0:1} != - ]] && RESULT="+$RESULT"
            [[ ${RESULT_GAP:0:1} != - ]] && RESULT_GAP="+$RESULT_GAP"
            TOTAL=$((BASH_REMATCH[16] / 10))
            TOTAL_GAP=$((TOTAL - BASH_REMATCH[17] / 10))
            [[ ${TOTAL:0:1} != - ]] && TOTAL="+$TOTAL"
            [[ ${TOTAL_GAP:0:1} != - ]] && TOTAL_GAP="+$TOTAL_GAP"
            printf "\e[1;12f%-5s\e[2;12f%-15s\e[3;12f%-15s" "${BASH_REMATCH[14]}" "$RESULT ($RESULT_GAP)" "$TOTAL ($TOTAL_GAP)"
        else
            printf "\e[1;12f\e[0K\e[2;12f\e[0K\e[3;12f\e[0K"
        fi
        ACTION="/b50b100${BASH_REMATCH[1]}"
        if [[ $ACTION =~ $RECENT ]]; then
            index=6
            for act in "${BASH_REMATCH[@]:1}"; do
                case $act in
                "") ACT="" ;;
                /) ACT="-" ;;
                f) ACT="fold" ;;
                k) ACT="check" ;;
                c) ACT="call" ;;
                *) ACT=$((${act/b/} / 10)) ;;
                esac
                printf "\e[%s;12f> %-9s" "$((++index))" "$ACT"
            done
        fi
        BETS=0
        CALLS=0
        LAST=""
        if [[ $ACTION =~ $UNCALLED ]]; then
            BETS=$((BETS + BASH_REMATCH[1] + BASH_REMATCH[2]))
            LAST=${BASH_REMATCH[2]}
        fi
        while [[ $ACTION =~ $CALLED ]]; do
            CALLS=$((CALLS + BASH_REMATCH[1]))
            ACTION="${ACTION/${BASH_REMATCH[0]}/}"
        done
        printf "\e[5;3f%-5s\e[10;0f" "$((CALLS / 5 + BETS / 10))"
    elif [[ $BODY =~ $ERROR ]]; then
        printf "\e[10;0f%s" "${BASH_REMATCH[1]}"
    fi
    CHIPS=$((20000 - CALLS))
    while read -rn1 key; do
        case $key in
        a) INCR="" ;;
        s) INCR=f ;;
        d) INCR=k ;;
        f) INCR=c ;;
        j) INCR="b$((${LAST:-150} * 2))" ;;
        k) INCR="b$((CALLS + LAST))" ;;
        l) INCR="b$(((CALLS + LAST) * 2))" ;;
        \;) INCR="b$CHIPS" ;;
        q) exit ;;
        *) continue ;;
        esac
        break
    done
    [[ ${INCR:1} -gt $CHIPS ]] && INCR="b$CHIPS"
    if [[ $INCR ]]; then
        INCR=",\"incr\":\"$INCR\""
        API=act
    else
        API=new_hand
    fi
    BODY=$(api "$API" "$TOKEN$INCR")
done
