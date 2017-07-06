#!/bin/bash

curl -o /tmp/fsrm.json https://fsrm.experiant.ca/api/v1/combined
jq -r .filters[] /tmp/fsrm.json > /tmp/fsrm.lst

sed -i 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/(/\\(/g; s/)/\\)/g; s/{/\\{/g; s/}/\\}/g; s/\@/\\@/g; s/\$/\\$/g' /tmp/fsrm.lst
sed -i 's/\ /\\ /g; s/\!/\\!/g; s/\#/\\#/g; s/\+/\\+/g; s/\-/\\-/g; s/\;/\\;/g; s/\,/\\,/g; s/\~/\\~/g; s/'\''/\\'\''/g' /tmp/fsrm.lst

mapfile -t known_ransom < /tmp/fsrm.lst

defInt=$(route | grep '^default' | grep -o '[^ ]*$')

while inotifywait -e modify /var/log/messages; do
    while read line; do
        if [[ "$line" = *smbd* ]]; then
               for ln in "${known_ransom[@]}"; do
                    if [[ "$line" = *smbd*$ln ]]; then
                        OIFS="$IFS"
                        IFS='[=,|]'
                        read -a clientIP <<< "${line}"
                        IFS="$OIFS"
                        echo "Detected ransomware activity from this ip: "${clientIP[1]//[[:space:]]/} >> /var/log/ransomware_ban.log
                        iptables -D INPUT -i $defInt -s ${clientIP[1]//[[:space:]]/} -j DROP
                        iptables -I INPUT -i $defInt -s ${clientIP[1]//[[:space:]]/} -j DROP
                    fi
                done
        fi
    done < /var/log/messages
done
