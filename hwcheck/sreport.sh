#!/bin/bash
#
# (c) 2015 Vladimir Smolensky <arizal@gmail.com> under the GPL
#     http://www.gnu.org/licenses/gpl.html
# CONFIG 
# Expected values
EMEM=15
ENUMDSK=14
ERAID="H700"
EDSKMODEL="EDGE Boost Pro Plus SSD"
EDSKSIZE=894
ECHASIS="PowerEdge R720xd"
# /CONFIG

# LIST OF SYSYESM

#Color print cprint($text, $color)
# colors 1-red,2-green,3-yellow,4-blue,5-purple,6-cyan,7-white
cprint() {
echo -en "\033[1;3${2}m${1}\033[0m"
}

leastprint() {
	value=`echo "$1" | sed -e 's/^[ \t]*//' | tr -d '\n'`
	if [ "$value" -lt "$2" ]; then
		cprint "$value" 1
		echo -n " is less then expected "
		cprint $2 4
		echo
	else
		cprint "$value" 2
		echo " OK"
	fi
}

matchprint() {
	text=`echo "$1" | sed -e 's/^[ \t]*//'`
	if [[ "$text" =~ "$2" ]]; then
		cprint "$text" 2
		echo " OK"
	else
		cprint "'$text'" 1
		echo -n " expected "
		cprint "'$2'" 4
		echo
	fi 
}

SYSTEMS="R510/2xE5620/128GB/14x960GBSSD/H700 R510/2xE5620/128GB/12x2TB+HDD/H700 R720xd/2xE5-2640v2/128GB/14x960GBSSD/H710p R720xd/2xE5-2640v2/128GB/12x2TB+SATA/H710p R730xd/2xE5-2680v3/256GB/14x960GBSSD/H730"

cprint "Select system configuration from the list below:" 7
echo 
select opt in $SYSTEMS; do 
	if [ "$opt" = "R510/2xE5620/128GB/14x960GBSSD/H700" ]; then
		EMEM=125
		ENUMDSK=14
		ERAID="H700"
		EDSKMODEL="EDGE Boost Pro Plus SSD"
		EDSKSIZE=894
		ECHASIS="PowerEdge R510"
		break
	elif [ "$opt" = "R510/2xE5620/128GB/12x2TB+HDD/H700" ]; then
		EMEM=125
		ENUMDSK=12
		ERAID="H700"
		EDSKMODEL=" "
		EDSKSIZE=1800
		ECHASIS="PowerEdge R510"
		break
	elif [ "$opt" = "R720xd/2xE5-2640v2/128GB/14x960GBSSD/H710p" ]; then
		EMEM=125
		ENUMDSK=14
		ERAID="H710P"
		EDSKMODEL="EDGE Boost Pro Plus SSD"
		EDSKSIZE=894
		ECHASIS="PowerEdge R720xd"
		break
	elif [ "$opt" = "R720xd/2xE5-2640v2/128GB/12x2TB+SATA/H710p" ]; then
		EMEM=125
		ENUMDSK=12
		ERAID="H710P"
		EDSKMODEL=" "
		EDSKSIZE=1800
		ECHASIS="PowerEdge R720xd"
		break
	elif [ "$opt" = "R730xd/2xE5-2680v3/256GB/14x960GBSSD/H730" ]; then
		EMEM=250
		ENUMDSK=14
		ERAID="H730"
		EDSKMODEL="EDGE Boost Pro Plus SSD"
		EDSKSIZE=894
		ECHASIS="PowerEdge R730xd"
		break
	else 
		cprint "Dont know about this system!" 1
		exit
	fi
done



#Get Total memory
totmem=`head -1 /proc/meminfo| awk '{ print $2 }'`
#in GB
totmem=$((totmem/1024/1024))

#Get Chasis
chasis=`dmidecode | grep "System Information" -A5| grep "Product Name:" | cut -f2 -d:`
dsknum=`megacli -EncInfo -aALL | grep "Number of Physical Drives"| cut -f2 -d: | sed -e 's/^[ \t]*//' | tr -d '\n'` 

echo -n "Memory[GB]: "
leastprint $totmem $EMEM
echo -n "Chasis: "
matchprint "$chasis" "$ECHASIS"

cprint "Checking megaraid" 6
echo 
echo -n "RAID Card model: "
megamodel=`megacli -AdpAllInfo -a0| grep "Product Name" | cut -f2 -d:`
matchprint "$megamodel" "$ERAID"
# Check number of drives
echo -n "Number of SSD/HDD: "
if [[ $dsknum =~ ^[0-9]+$ ]]; then
	leastprint $dsknum $ENUMDSK
else 
	cprint "Couldn't get number of disks!" 1
	echo
fi

#Check drive models
echo "Checking drive models"
for ((n=0; n<dsknum; n++)); do
	dskmodel=`megacli -pdinfo -physdrv [32:${n}] -a0| grep "Inquiry Data:" | cut -f2 -d:`
	echo -n "Slot $n: " 
	matchprint "$dskmodel" "$EDSKMODEL"
done
#Check drive sizes
echo "Checking drive sizes"
for ((n=0; n<dsknum; n++)); do
	dsksize=`megacli -pdinfo -physdrv [32:${n}] -a0| grep "Raw Size:" | awk '{ print $3 }'`
	if megacli -pdinfo -physdrv [32:${n}] -a0| grep "Raw Size:" | grep ' TB '> /dev/null; then
		dsksize=$(awk "BEGIN {printf \"%.0f\",${dsksize}*1000}")
	else
		dsksize=`echo $dsksize | cut -f1 -d.`
	fi
	echo -n "Slot $n: " 
	leastprint "$dsksize" $EDSKSIZE
done
# Check connectivity
echo "Checkint network connection... "
for i in `ifconfig -a | sed 's/[ \t].*//;/^$/d;/^lo/d;s/://'`; do
	if ethtool $i | grep "Link detected: yes" >/dev/null; then
		link="$link $i"
		linkspeed=`ethtool $i | grep "Speed: " | cut -f2 -d: | sed -e 's/Mb\/s$//' | sed -e 's/^[ \t]*//' | tr -d '\n'`
		if [ -n "$linkspeed" ]; then
			if [ $linkspeed -eq 10000 ]; then
				tengb=1
			fi
		fi
	fi
done
if [ -z "$link" ]; then
	cprint "No network link detected: ERROR" 1
else 
	echo -n "We have link on: "
	cprint "$link" 2
fi
echo
if [ -z "$tengb" ]; then
	cprint "No 10Gbit link detected!" 3
	echo
fi
