#!/bin/bash

function string_replace {
    #DOC: "${string/match/replace}"
    string=$1
    echo "${string//$2/$3}"
}

i=0
while read line
do
  if [ "$line" != "" ]; then
     char=${line:0:1}
     if [ "$char" != "*" ]; then
        LINE="*$line"
     fi
     line=$(string_replace "$line" "\." "\.")
     line=$(string_replace "$line" "\[" "\[")
     line=$(string_replace "$line" "\]" "\]")
     line=$(string_replace "$line" "\(" "\(")
     line=$(string_replace "$line" "\)" "\)")
     line=$(string_replace "$line" "\{" "\{")
     line=$(string_replace "$line" "\}" "\}")
     line=$(string_replace "$line" "\@" "\@")
     line=$(string_replace "$line" "\$" "\\$")
     line=$(string_replace "$line" "\ " "\ ")
     line=$(string_replace "$line" "\!" "\!")
     line=$(string_replace "$line" "\#" "\#")
     line=$(string_replace "$line" "\+" "\+")
     line=$(string_replace "$line" "\-" "\-")
     line=$(string_replace "$line" "\;" "\;")
     line=$(string_replace "$line" "\," "\,")
     line=$(string_replace "$line" "\'" "\'")
     line=$(string_replace "$line" "\~" "\~")
     known_ransom[$i]="$line"
     i=$((i+1))
  fi
done < ./fsrm.lst

line=""
while inotifywait -e modify /var/log/messages; do
    iCount=0
    while read line; do
        iBool=0
        for i in "${known_ransom[@]}"
        do
           if [[ "$line" = *smbd*$i ]]; then
                iBool=1
                (( iCount+ _+ _ ))
                OIFS="$IFS"
                IFS='[=,|]'
                read -a clientIP <<< "${line}"
                IFS="$OIFS"
                echo "Detecting ransomware activity from this ip: "${clientIP[1]//[[:space:]]/} >> /var/log/ransomware_ban.log
                iptables -D INPUT -i eth1 -s ${clientIP[1]//[[:space:]]/} -j DROP
                iptables -I INPUT -i eth1 -s ${clientIP[1]//[[:space:]]/} -j DROP
           fi
         done
    done < /var/log/messages
done