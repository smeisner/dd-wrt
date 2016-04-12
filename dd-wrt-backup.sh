#!/bin/sh 
 # 
 # This shell script creates a shell file with lines of the form 
 # nvram set x="y" 
 # for every nvram variable found from 
 # nvram show 
 # 
 DATE=`date +%m%d%Y` 
 MAC=`nvram get lan_hwaddr | tr -d ":"` 
 FILE=${MAC}.${DATE} 
 CUR_DIR=`dirname $0` 
 FOLDER=/opt/var/backups 
 TO_ALL=${FOLDER}/${MAC}.${DATE}.all.sh 
 TO_INCLUDE=${FOLDER}/${MAC}.${DATE}.essential.sh 
 TO_EXCLUDE=${FOLDER}/${MAC}.${DATE}.dangerous.sh 
 FTPS=ftp://192.168.10.210/backups 
 USERPASS=user:pass 

 nvram show 2>/dev/null | egrep '^[a-zA-Z].*=' | awk -F= '{print $1}' | grep -v "[ /+<>,:;]" | sort -u >/tmp/all_vars 

 # 
 echo -e "#!/bin/sh\n#\necho \"Write variables\"\n" | tee -i ${TO_EXCLUDE} | tee -i  ${TO_ALL} > ${TO_INCLUDE} 

 cat /tmp/all_vars | while read var 
 do 
   if echo ${var} | grep -q -f "${CUR_DIR}/vars_to_skip" ; then 
     bfile=$TO_EXCLUDE 
   else 
     bfile=$TO_INCLUDE 
   fi 

   # get the data out of the variable 
   data=`nvram get ${var}` 
   if [ "${data}" == "" ] ; then 
     echo -e "nvram set ${var}="  | tee -ia  ${TO_ALL} >> ${bfile} 
   else 
     # write the var to the file and use \ for special chars: (\$`") 
     echo -en "nvram set ${var}=\"" | tee -ia ${TO_ALL} >> ${bfile} 
     echo -n "${data}" | sed 's/\\/\\\\/g' | sed 's/`/\\`/g' | sed 's/\$/\\\$/g' | sed 's/\"/\\"/g' | tee -ia  ${TO_ALL} >> ${bfile} 
     echo -e "\"" | tee -ia  ${TO_ALL} >> ${bfile} 
   fi 

 done 

 rm /tmp/all_vars 

 echo -e "\n# Commit variables\necho \"Save variables to nvram\"\nnvram commit"  | tee -ia  ${TO_ALL} | tee -ia  ${TO_EXCLUDE} >> ${TO_INCLUDE} 
 chmod +x ${TO_ALL} 
 chmod +x ${TO_INCLUDE} 
 chmod +x ${TO_EXCLUDE} 

 tar cpf - -C / "${TO_INCLUDE}" 2>/dev/null | /opt/bin/gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.essential.sh.tgz" -T - 
 tar cpf - -C / "${TO_EXCLUDE}" 2>/dev/null | /opt/bin/gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.dangerous.sh.tgz" -T - 
 tar cpf - -C / "${TO_ALL}" 2>/dev/null | /opt/bin/gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.all.sh.tgz" -T - 
 