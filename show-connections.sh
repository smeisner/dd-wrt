#!/bin/sh

InputFile=/proc/net/ip_conntrack
TempFile=/tmp/ip_contrack.tmp
Spaces='                                                    '
sSpaces='                                 '
netaddr=`ifconfig br0 | grep Bcast | cut -d":" -f3 | sed 's/Mask//' | sed 's/  //' | sed 's/255//' | sed 's/\(.*\)./\1 /' | sed 's/ //'`

cp $InputFile $TempFile

echo -e "Network address: $netaddr"
echo -e "Outbound connections:"
echo -e "Local                              Remote                                                Port"
echo -e "----------------------------------+-----------------------------------------------------+-----------"
while IFS= read -r line <&3; do
    p=`echo $line | cut -d" " -f4`
    if [[ "$p" == "ESTABLISHED" ]]
    then
      q=`echo $line | cut -d"=" -f2 | sed 's/dst=//' | sed 's/dst//'`
      if [[ ${q:0:${#netaddr}} == "$netaddr" ]]
      then
        r=`echo $line | cut -d"=" -f8 | sed 's/dst=//' | sed 's/dst//'`
        port=`echo $line | cut -d"=" -f5 | sed 's/packets=//' | sed 's/packets//'`
        remote=`nslookup $r | grep 'Address 1' | tail -1 | cut -d' ' -f4`
        local=`nslookup $q | grep 'Address 1' | tail -1 | cut -d' ' -f4`
        if [[ "$local" == "" ]]; then local=$q; fi
        if [[ "$remote" == "" ]]; then remote=$r; fi
        printf '%s%s%s%s%s\n' "$local ${sSpaces:${#local}} $remote ${Spaces:${#remote}} $port"
      fi
    fi
  done 3< "$TempFile"

echo -e "\nInbound connections:"
echo -e "Remote                                                Local                              Port"
echo -e "-----------------------------------------------------+----------------------------------+-----------"
while IFS= read -r line <&3; do
    p=`echo $line | cut -d" " -f4`
    if [[ "$p" == "ESTABLISHED" ]]
    then
      r=`echo $line | cut -d"=" -f2 | sed 's/dst=//' | sed 's/dst//'`
      if [[ ${r:0:${#netaddr}} != "$netaddr" ]]
      then
        q=`echo $line | cut -d"=" -f8 | sed 's/dst=//' | sed 's/dst//'`
        port=`echo $line | cut -d"=" -f5 | sed 's/packets=//' | sed 's/packets//'`
        remote=`nslookup $r | grep 'Address 1' | tail -1 | cut -d' ' -f4`
        local=`nslookup $q | grep 'Address 1' | tail -1 | cut -d' ' -f4`
        if [[ "$local" == "" ]]; then local=$q; fi
        if [[ "$remote" == "" ]]; then remote=$r; fi
        printf '%s%s%s%s%s\n' "$remote ${Spaces:${#remote}} $local ${sSpaces:${#local}} $port"
      fi
    fi
  done 3< "$TempFile"

rm $TempFile


