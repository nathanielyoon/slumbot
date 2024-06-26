#!/usr/bin/env bash
# shellcheck disable=2034,2155,2162

trap 'printf "\e[10;0f\e[0K\e[?25h"' 0
BUTTON="Ⓓ "
REGEX='"action":\s*"([/0-9fkcb]*)",\s*"client_pos":\s*([01]),\s*"hole_cards":\s*\[\s*"([2-9TJQKA][shdc])",\s*"([2-9TJQKA][shdc])"\s*\],\s*"board":\s*\[[[:space:]"]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]"]*\],?(\s*"bot_hole_cards":\s*\[\s*"([2-9TJQKA][shdc])",\s*"([2-9TJQKA][shdc])"\s*\],\s*"winnings":\s*(-?[0-9]+),\s*"won_pot":\s*-?[0-9]+,\s*"session_num_hands":\s*(-?[0-9]+),\s*"baseline_winnings":\s*(-?[0-9]+),\s*"session_total":\s*(-?[0-9]+),\s*"session_baseline_total":\s*(-?[0-9]+))?'
ERROR='"error_msg":\s*"([[:print:]]+)"'
CALLED='b([0-9]+)c'
UNCALLED='([0-9]+)?b([0-9]+)$'
CURRENT='([/kcf]|b[0-9]+)?([/kcf]|b[0-9]+)?([/kcf]|b[0-9]+)?$'
cards() {
    for card; do
        if [[ -n $card ]]; then
            case ${card:1:1} in
            s) local suit="0♤" ;;
            h) local suit="1♡" ;;
            d) local suit="4♢" ;;
            c) local suit="2♧" ;;
            esac
            printf "\e[3%sm%s%s\e[0m\e[2C" "${suit:0:1}" "${card:0:1}" "${suit:1:1}"
        else
            printf "  \e[2C"
        fi
    done
}
printf "\e[?25l\e[2J\e[H╭──╮╭──╮
│  ││  │
╰──╯╰──╯
┌──────┐  ╭──╮╭──╮╭──╮╭──╮╭──╮
│      │  │  ││  ││  ││  ││  │
└──────┘  ╰──╯╰──╯╰──╯╰──╯╰──╯
╭──╮╭──╮
│  ││  │
╰──╯╰──╯\e[H"
BODY=$(curl -s https://slumbot.com/api/new_hand -H content-type:\ application/json -d {})
TOKEN="\"token\":\"${BODY: -38:36}\""
while true; do
    # clear message
    printf "\e[10;0f\e[0K"
    if [[ $BODY =~ $REGEX ]]; then
        POSITION=${BASH_REMATCH[2]}
        printf "\e[2;9f%s\e[8;9f%s\e[8;2f" "${BUTTON:$POSITION:1}" "${BUTTON:$((POSITION ^ 1)):1}"
        cards "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"
        printf "\e[5;12f"
        cards "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" "${BASH_REMATCH[7]}" "${BASH_REMATCH[8]}" "${BASH_REMATCH[9]}"
        printf "\e[2;2f"
        cards "${BASH_REMATCH[11]}" "${BASH_REMATCH[12]}"
        if [[ ${BASH_REMATCH[10]} ]]; then
            HANDS=${BASH_REMATCH[14]}
            RESULT=$((BASH_REMATCH[13] / 10))
            [[ ${RESULT:0:1} != - ]] && RESULT="+$RESULT"
            BOT_RESULT=$((BASH_REMATCH[15] / 10))
            [[ ${BOT_RESULT:0:1} != - ]] && BOT_RESULT="+$BOT_RESULT"
            TOTAL=$((BASH_REMATCH[16] / 10))
            [[ ${TOTAL:0:1} != - ]] && TOTAL="+$TOTAL"
            BOT_TOTAL=$((BASH_REMATCH[17] / 10))
            [[ ${BOT_TOTAL:0:1} != - ]] && BOT_TOTAL="+$BOT_TOTAL"
            printf "\e[1;12f%-5s\e[2;12f%-15s\e[3;12f%-15s" "$HANDS" "$TOTAL ($BOT_TOTAL)" "$RESULT ($BOT_RESULT)"
        else
            printf "\e[1;12f\e[0K\e[2;12f\e[0K\e[3;12f\e[0K"
        fi
        ACTION="/b50b100${BASH_REMATCH[1]}"
        if [[ $ACTION =~ $CURRENT ]]; then
            index=6
            for match in "${BASH_REMATCH[@]:1}"; do
                case $match in
                "") ACT="" ;;
                /)
                    lengther=${ACTION//\//}
                    case $((${#ACTION} - ${#lengther})) in
                    1) ACT="(preflop)" ;;
                    2) ACT="(flop)" ;;
                    3) ACT="(turn)" ;;
                    4) ACT="(river)" ;;
                    esac
                    ;;
                f) ACT="fold" ;;
                k) ACT="check" ;;
                c) ACT="call" ;;
                *)
                    ACT="${match/b/}"
                    ACT=$((ACT / 10))
                    ;;
                esac
                [[ $ACT ]] && printf "\e[%s;12f> %-9s" "$((++index))" "$ACT"
            done
        fi
        declare -i POT SIZE
        if [[ $ACTION =~ $UNCALLED ]]; then
            POT+=$((BASH_REMATCH[1] + BASH_REMATCH[2]))
            SIZE+=${BASH_REMATCH[2]}
        fi
        while [[ $ACTION =~ $CALLED ]]; do
            POT=$((POT + BASH_REMATCH[1] * 2))
            ACTION=${ACTION/${BASH_REMATCH[0]}/}
        done
        printf "\e[5;3f%-5s\e[10;0f" "$((POT / 10))"
    elif [[ $BODY =~ $ERROR ]]; then
        printf "\e[10;0f%s" "${BASH_REMATCH[1]}"
    else
        printf "\e[10;0f%s" "$BODY"
    fi
    read -rn1 key
    CHIPS=$((20000 - POT / 2))
    API=act
    INCR=""
    case $key in
    a) API=new_hand ;;
    s) INCR=f ;;
    d) INCR=k ;;
    f) INCR=c ;;
    j) INCR="b$((SIZE * 2))" ;;
    k) INCR="b$((POT / 2))" ;;
    l) INCR="b$POT" ;;
    \;) INCR="b$CHIPS" ;;
    q) exit ;;
    esac
    [[ ${INCR:0:1} == b ]] && [[ ${INCR:1} -gt $CHIPS ]] && INCR="b$CHIPS"
    [[ $INCR ]] && INCR=",\"incr\":\"$INCR\""
    BODY=$(curl -s "https://slumbot.com/api/$API" -H content-type:\ application/json -d "{$TOKEN$INCR}")
done
