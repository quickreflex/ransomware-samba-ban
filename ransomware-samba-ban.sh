#!/bin/bash

function string_replace {
    #DOC: "${string/match/replace}"
    string=$1
    echo "${string//$2/$3}"
}

curl -o /tmp/fsrm.json https://fsrm.experiant.ca/api/v1/combined
jq -r .filters[] /tmp/fsrm.json > /tmp/fsrm.lst

i=0
mapfile -t known_ransom < /tmp/fsrm.lst

for ln in "${known_ransom[@]}"; do
    ln=$(string_replace "$ln" "\." "\.")
    ln=$(string_replace "$ln" "\[" "\[")
    ln=$(string_replace "$ln" "\]" "\]")
    ln=$(string_replace "$ln" "\(" "\(")
    ln=$(string_replace "$ln" "\)" "\)")
    ln=$(string_replace "$ln" "\{" "\{")
    ln=$(string_replace "$ln" "\}" "\}")
    ln=$(string_replace "$ln" "\@" "\@")
    ln=$(string_replace "$ln" "\$" "\\$")
    ln=$(string_replace "$ln" "\ " "\ ")
    ln=$(string_replace "$ln" "\!" "\!")
    ln=$(string_replace "$ln" "\#" "\#")
    ln=$(string_replace "$ln" "\+" "\+")
    ln=$(string_replace "$ln" "\-" "\-")
    ln=$(string_replace "$ln" "\;" "\;")
    ln=$(string_replace "$ln" "\," "\,")
    ln=$(string_replace "$ln" "\'" "\'")
    ln=$(string_replace "$ln" "\~" "\~")
    known_ransom[$i]="$ln"
    i=$((i+1))
done

while inotifywait -e modify /var/log/messages; do
    mapfile -t log_messages < /var/log/messages
    for line in "${log_messages[@]}"; do
	if [[ "$line" = *smbd* ]]; then
		for ln in "${known_ransom[@]}"; do
		   if [[ "$line" = *smbd*$ln ]]; then
			OIFS="$IFS"
			IFS='[=,|]'
			read -a clientIP <<< "${line}"
			IFS="$OIFS"
			echo "Detecting ransomware activity from this ip: "${clientIP[1]//[[:space:]]/} >> /var/log/ransomware_ban.log
			iptables -D INPUT -i eth1 -s ${clientIP[1]//[[:space:]]/} -j DROP
			iptables -I INPUT -i eth1 -s ${clientIP[1]//[[:space:]]/} -j DROP
		   fi
		done
	fi
    done
done
