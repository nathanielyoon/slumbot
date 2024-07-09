#!/usr/bin/env bash
# shellcheck disable=2034,2155,2162,2317

trap 'printf "\e[12;1f\e[0K\e[?25h"' 0
BUTTON="Ⓓ "
REGEX='"action":\s*"([/0-9fkcb]*)",\s*"client_pos":\s*([01]),\s*"hole_cards":\s*\[\s*"([2-9TJQKA][shdc])",\s*"([2-9TJQKA][shdc])"\s*\],\s*"board":\s*\[[[:space:]"]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]",]*([2-9TJQKA][shdc])?[[:space:]"]*\],?(\s*"bot_hole_cards":\s*\[\s*"([2-9TJQKA][shdc])",\s*"([2-9TJQKA][shdc])"\s*\],\s*"winnings":\s*(-?[0-9]+),\s*"won_pot":\s*-?[0-9]+,\s*"session_num_hands":\s*(-?[0-9]+),\s*"baseline_winnings":\s*(-?[0-9]+),\s*"session_total":\s*(-?[0-9]+),\s*"session_baseline_total":\s*(-?[0-9]+))?'
ERROR='"error_msg":\s*"([[:print:]]+?)"'
RECENT='([/kc]|b[0-9]+)?([/kc]|b[0-9]+)([/kc]|b[0-9]+)([/fkc]|b[0-9]+)$'
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
preflop() {
    local value_1=${1:0:1}
    local value_2=${2:0:1}
    if [[ "$value_1" == "$value_2" ]]; then return 1; fi
    if [[ "${1:1:1}" == "${2:1:1}" ]]; then return 1; fi
    case $value_1 in
    A | K | Q) return 1 ;;
    esac
}

printf "\e[?25l\e[2J\e[H╭──╮╭──╮   >
│  ││  │   >
╰──╯╰──╯   >
           >
╭──╮╭──╮╭──╮╭──╮╭──╮
│  ││  ││  ││  ││  │
╰──╯╰──╯╰──╯╰──╯╰──╯
           >
╭──╮╭──╮   ┌───────┐
│  ││  │   │       │
╰──╯╰──╯   └───────┘"
MANUAL_PREFLOP=0
MANUAL_BET=0
while getopts :c:pb flag; do
    case $flag in
    c) printf "\e[13;1f%s" "$(<"$OPTARG")" ;;
    p) MANUAL_PREFLOP=1 ;;
    b) MANUAL_BET=1 ;;
    *) exit 1 ;;
    esac
done

BODY=$(api new_hand)
TOKEN="\"token\":\"${BODY: -38:36}\""

while true; do
    # clear input/message
    printf "\e[8;14f\e[0K\e[12;1f\e[0K"
    if [[ $BODY =~ $REGEX ]]; then
        # fold hand if necessary
        if [[ $MANUAL_PREFLOP == 0 ]] && preflop "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; then
            # clear hole cards
            printf "\e[10;2f"
            cards "" ""

            # clear board
            printf "\e[6;2f"
            cards "" "" "" "" ""

            # clear bot hole cards
            printf "\e[2;2f"
            cards "" ""

            # clear actions
            printf "\e[1;14f\e[0K\e[2;14f\e[0K\e[3;14f\e[0K\e[4;14f\e[0K\e[8;14f\e[0K"

            # clear chips, pot, button
            printf "\e[4;1f           \e[8;1f           \e[10;13f      \e[2;9f \e[10;9f "

            # fold current hand
            api act "$TOKEN,\"incr\":\"f\"" >/dev/null

            # get new hand
            BODY=$(api new_hand "$TOKEN")

            # start over to check it
            continue
        fi
        # print button
        printf "\e[2;9f%s\e[10;9f%s\e[10;2f" "${BUTTON:${BASH_REMATCH[2]}:1}" "${BUTTON:$((BASH_REMATCH[2] ^ 1)):1}"

        # print hole cards
        cards "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"

        # print board
        printf "\e[6;2f"
        cards "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" "${BASH_REMATCH[7]}" "${BASH_REMATCH[8]}" "${BASH_REMATCH[9]}"

        # print bot hole cards
        printf "\e[2;2f"
        cards "${BASH_REMATCH[11]}" "${BASH_REMATCH[12]}"

        # if there are results
        if [[ -n ${BASH_REMATCH[10]} ]]; then
            # flag yes for later
            RESULTS=1

            # winnings, signed
            MY_RESULT=$((BASH_REMATCH[13] / 10))
            [[ ${MY_RESULT:0:1} != - ]] && MY_RESULT="+$MY_RESULT"

            # session winnings, signed
            MY_TOTAL=$((BASH_REMATCH[16] / 10))
            BOT_TOTAL=$((BASH_REMATCH[17] / 10))
            [[ ${MY_TOTAL:0:1} != - ]] && MY_TOTAL="+$MY_TOTAL"
            [[ ${BOT_TOTAL:0:1} != - ]] && BOT_TOTAL="+$BOT_TOTAL"

            # print stats
            printf "\e[10;14f%-6s" "$MY_RESULT"
            printf "\e[8;2f%-5s\e[4;2f%-5s" "$MY_TOTAL" "$BOT_TOTAL"
        else
            # flag no for later
            RESULTS=0
        fi

        # action
        ACTION="/b50b100${BASH_REMATCH[1]}"

        # print recent actions
        if [[ $ACTION =~ $RECENT ]]; then
            index=0
            for act in "${BASH_REMATCH[@]:1}"; do
                case $act in
                "") ACT="" ;;
                /) ACT="-" ;;
                f) ACT="fold" ;;
                k) ACT="check" ;;
                c) ACT="call" ;;
                *) ACT=$((${act/b/} / 10)) ;;
                esac
                printf "\e[%s;14f%-5s" "$((++index))" "$ACT"
            done
        fi

        # reset accumulators
        BETS=0
        CALLS=0
        MY_LAST=""
        BOT_LAST=""

        # account for un-called bets
        if [[ $ACTION =~ $UNCALLED ]]; then
            MY_LAST=${BASH_REMATCH[1]}
            BOT_LAST=${BASH_REMATCH[2]}
            BETS=$((BETS + MY_LAST + BOT_LAST))
        fi

        # sum called bets
        while [[ $ACTION =~ $CALLED ]]; do
            CALLS=$((CALLS + BASH_REMATCH[1]))
            ACTION="${ACTION/${BASH_REMATCH[0]}/}"
        done

        # effective chips
        CHIPS=$((20000 - CALLS))

        if [[ $RESULTS == 0 ]]; then
            # print chips
            printf "\e[8;1f %-10s\e[4;1f %-10s" "$(((CHIPS - MY_LAST) / 10))" "$(((CHIPS - BOT_LAST) / 10))"

            # print pot
            printf "\e[10;14f%-5s" "$((CALLS / 5 + BETS / 10))"
        fi

    elif [[ $BODY =~ $ERROR ]]; then
        printf "\e[12;1f%s" "${BASH_REMATCH[1]}"
    fi
    # go to input
    printf "\e[8;14f"
    if [[ $MANUAL_BET == 0 ]]; then
        while read -rn1 key; do
            case $key in
            a) INCR="" ;;
            s) INCR=f ;;
            d) INCR=k ;;
            f) INCR=c ;;
            j) INCR="b$((${BOT_LAST:-150} * 2))" ;;
            k) INCR="b$((CALLS + BOT_LAST))" ;;
            l) INCR="b$(((CALLS + BOT_LAST) * 2))" ;;
            \;) INCR="b$CHIPS" ;;
            g)
                api act "$TOKEN,f" >/dev/null
                INCR=""
                ;;
            $'\x1b') printf "\e[8;14f\e[0K" ;;
            q) exit ;;
            *) continue ;;
            esac
            break
        done
    else
        SIZE=""
        while read -rn1 key; do
            case $key in
            a) INCR="" ;;
            s) INCR=f ;;
            d) INCR=k ;;
            f) INCR=c ;;
            0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9)
                SIZE="$SIZE$key"
                continue
                ;;
            j | k | l) INCR="b$((SIZE * 10))" ;;
            g)
                api act "$TOKEN,f" >/dev/null
                INCR=""
                ;;
            $'\x1b')
                printf "\e[8;14f\e[0K"
                SIZE=""
                continue
                ;;
            q) exit ;;
            *) continue ;;
            esac
            break
        done
    fi
    [[ ${INCR:1} -gt $CHIPS ]] && INCR="b$CHIPS"
    if [[ $INCR ]]; then
        INCR=",\"incr\":\"$INCR\""
        API=act
    else
        API=new_hand
    fi
    BODY=$(api "$API" "$TOKEN$INCR")
done
