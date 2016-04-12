#!/bin/sh
data=`nvram get static_leases | awk 'BEGIN { FS="="; RS=" " } {a=1; while ( a<NF ) { b=a+1; c=a+2; d=a+3; print $c "=" $b "=" $a "=" $d; a=+4; } }' | sort | awk 'BEGIN { FS="="; RS="\n" } { a=1; while ( a<NF ) { b=a+1; c=a+2; d=a+3; printf $c "=" $b "=" $a "=" $d " "; a+=4 } }' | awk '{sub(/[ \t]+$/, "")};1'`
nvram set static_leases="${data}"
nvram commit

