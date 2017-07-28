#!/bin/bash

INFILE=$1
OUTFILE=$2

echo " "
echo " ##### idd (interactive dd) #####"

#declare the "help" function to tell clueless users how to use idd
function helpme(){
    echo ""
    echo "Use like 'idd /filepath/inputfile /filepath/outputfile'"
    echo ""
    echo "You must, of course, run idd as root unless your user has permissions"
    echo "to access the files and/or devices you wish to copy to and from."
    echo ""
}

if [ $(echo ${#INFILE}) -lt 2 ]; then
    echo ""
    echo "Error: No arguments specified."
    helpme
    exit
fi
if [ "$1" = "--help" ] || [ "$1" = "-h" ] ; then
    helpme
    exit
fi
if [ $(echo ${#OUTFILE}) -lt 2 ]; then
    echo ""
    echo "Error: No output file specified."
    helpme
    exit
fi
PV=$(which pv)
if [ $(echo ${#PV}) -lt 2 ]; then
    echo ""
    echo "Error: You must install pv for idd to work"
    helpme
    exit
fi

#is this a regular file?
if [ -f $INFILE ]; then
    FILESIZE=$(stat -c %s $INFILE)
else
    #this must either be non-existent, or a different file type, like block (hdd)
    NOEX=$(stat $INFILE 2> /dev/null | grep "No such file")
    if [ $(echo ${#NOEX}) -gt 2 ]; then
		echo ""
		echo "Error: Input file not found."
		helpme
		exit
    else
		#try to grep out the file size
		BF=$(stat $INFILE 2> /dev/null | grep "block special file")
		if [ $(echo ${#BF}) -lt 2 ]; then
			echo ""
			echo "Error: Unsupported input file type. Use only regular files and block files (disks)."
			helpme
			exit
		else
			#get size in bytes of block file (drive or partition)
			FILESIZE=$(fdisk -l $INFILE | grep "Disk $INFILE:" | sed -n 's/.*, \([0-9]\+\) bytes.*/\1/p')
		fi
    fi
fi

echo "Ready to copy."
echo "From: '$INFILE'"
echo "Size: $FILESIZE"
echo "To: '$OUTFILE'"
echo ""
read -p "Type 'y' to confirm, 'n' to cancel : " CONFIRMATION
if [ "$CONFIRMATION" != "y" ] && [ "$CONFIRMATION" != "Y" ]; then
    echo "Copy operation canceled."
    exit
else
	echo ""
fi

#is the file big enough to warrant doing a test for the most efficient block size?
if [ "$(echo "$FILESIZE < 524288000" | bc)" = "1" ]; then
    #under 500 Mb? Just run dd and skip fancy calcs
    echo "Starting copy with default block size . . ."
    pv -s $FILESIZE $INFILE | dd bs=1k of=$OUTFILE 2> /dev/null
    echo "Copy complete."
    exit
fi

#if we get here, then the file must be over 500 Mb, so test some block sizes
echo "Testing for optimal block size . . ."

START=`date +%s.%N`
dd count=20480 if=$INFILE of=$OUTFILE bs=1K 2> /dev/null
END=`date +%s.%N`
ELAPSE=$(echo "$END - $START"|bc)
DBS='1K'

START=`date +%s.%N`
dd count=10240 if=$INFILE of=$OUTFILE bs=2K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='2K'
fi

START=`date +%s.%N`
dd count=5120 if=$INFILE of=$OUTFILE bs=4K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='4K'
fi

START=`date +%s.%N`
dd count=2560 if=$INFILE of=$OUTFILE bs=8K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='8K'
fi

START=`date +%s.%N`
dd count=1280 if=$INFILE of=$OUTFILE bs=16K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='16K'
fi

START=`date +%s.%N`
dd count=160 if=$INFILE of=$OUTFILE bs=128K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='128K'
fi

START=`date +%s.%N`
dd count=80 if=$INFILE of=$OUTFILE bs=256K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='256K'
fi

START=`date +%s.%N`
dd count=40 if=$INFILE of=$OUTFILE bs=512K 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    ELAPSE=$ELAPSED
    DBS='512K'
fi

START=`date +%s.%N`
dd count=20 if=$INFILE of=$OUTFILE bs=1M 2> /dev/null
END=`date +%s.%N`
ELAPSED=$(echo "$END - $START"|bc)

if [ $(echo "$ELAPSED < $ELAPSE" | bc) = "1" ]; then
    DBS='1M'
fi

echo "Starting copy with $DBS block size . . ."

dd bs=$DBS if=$INFILE 2> /dev/null | pv -s $FILESIZE | dd bs=$DBS of=$OUTFILE 2> /dev/null

echo "Copy complete."

exit
