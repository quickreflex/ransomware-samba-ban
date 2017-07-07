#!/bin/bash

curl -o /tmp/fsrm.json https://fsrm.experiant.ca/api/v1/combined
jq -r .filters[] /tmp/fsrm.json > /tmp/fsrm.lst

sed -i 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/(/\\(/g; s/)/\\)/g; s/{/\\{/g; s/}/\\}/g; s/\@/\\@/g; s/\$/\\$/g' /tmp/fsrm.lst
sed -i 's/\ /\\ /g; s/\!/\\!/g; s/\#/\\#/g; s/\+/\\+/g; s/\-/\\-/g; s/\;/\\;/g; s/\,/\\,/g; s/\~/\\~/g; s/'\''/\\'\''/g' /tmp/fsrm.lst

mapfile -t known_ransom < /tmp/fsrm.lst

defInt=$(route | grep '^default' | grep -o '[^ ]*$')

while inotifywait -e modify /var/log/messages; do
    grep '"*smbd"*' /var/log/messages > /tmp/samba_log.lst
    while read line; do
          for ln in "${known_ransom[@]}"; do
               if [[ "$line" = *smbd*$ln ]]; then
                   OIFS="$IFS"
                   IFS='[=,|]'
                   read -a clientIP <<< "${line}"
                   IFS="$OIFS"
                   chkRule=$(iptables '-L' '-n' | grep '^DROP.*${clientIP[1]//[[:space:]]/}.*')
                   if [[ $chkRule == "" ]]; then
                        iptables -I INPUT -i $defInt -s ${clientIP[1]//[[:space:]]/} -j DROP
                        echo "Detected ransomware activity from this ip: "${clientIP[1]//[[:space:]]/} >> /var/log/ransomware_ban.log
                   fi
               fi
          done
    done < /tmp/samba_log.lst
done
