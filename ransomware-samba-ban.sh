#!/bin/bash

while true; do
    if curl --output /dev/null --silent --head --fail https://fsrm.experiant.ca/api/v1/combined; then
        curl -o /tmp/fsrm.json https://fsrm.experiant.ca/api/v1/combined && break
    fi
done

jq -r .filters[] /tmp/fsrm.json > /tmp/fsrm.lst

sed -i 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g;  s/\@/\\@/g; s/\$/\\$/g; s/\ /\\ /g; s/\!/\\!/g' /tmp/fsrm.lst
sed -i 's/\#/\\#/g; s/\+/\\+/g; s/\-/\\-/g; s/\;/\\;/g; s/\,/\\,/g; s/\~/\\~/g; s/'\''/\\'\''/g; s/\*/\.*/g' /tmp/fsrm.lst

mapfile -t known_ransom < /tmp/fsrm.lst

defInt=$(route | grep '^default' | grep -o '[^ ]*$')

while inotifywait -e modify /var/log/messages; do
    : > /tmp/samba_log.lst
    for ln in "${known_ransom[@]}"; do
          grep --text ".*smbd.*$ln.$" /var/log/messages >> /tmp/samba_log.lst
    done
    while read line; do
          OIFS="$IFS"
          IFS='[=,|]'
          read -a clientIP <<< "${line}"
          IFS="$OIFS"
          chkRule=$(iptables '-L' '-n' | grep '^DROP.*${clientIP[1]//[[:space:]]/}.*')
          if [[ $chkRule == "" ]]; then
                  iptables -I INPUT -i $defInt -s ${clientIP[1]//[[:space:]]/} -j DROP
                  echo "Detected ransomware activity from this ip: "${clientIP[1]//[[:space:]]/} >> /var/log/ransomware_ban.log
          fi
    done < /tmp/samba_log.lst
done