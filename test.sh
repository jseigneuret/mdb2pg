#!/bin/sh
	: 'colon is the comment command'
	: 'default is nroff ($N), section 1 ($s)'
	N=n s=1

	for i
	do case $i in
	   [1-9]*)      s=$i ;;
	   -t)  N=t ;;
	   -n)  N=n ;;
	   -*)  echo unknown flag \'$i\' ;;
	   *)   if test -f man$s/$i.$s
		then    ${N}roff man0/${N}aa man$s/$i.$s
		else    : 'look through all manual sections'
			found=no
			for j in 1 2 3 4 5 6 7 8 9
			do if test -f man$j/$i.$j
			   then man $j $i
				found=yes
			   fi
			done
			case $found in
			     no) echo \'$i: manual page not found\'
			esac
		fi
	   esac
	done
