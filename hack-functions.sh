#!/bin/bash 
#
# hack-functions 1.5 - bash functions to do little hacks
#
# Copyright (C) 2012 - 2013 hack-functions authors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

hf_user_path="$HOME/.config/hack-functions"
hf_cache="$hf_user_path/cache/asm"

## internal functions

checkdir() { test -d $hf_cache || mkdir -p $hf_cache; }

## base conversion

dec2hex()
{
    local USAGE="convert decimal to hex equivalent

    Param:
        number - integer to be converted

    Output:
        \$ dec2hex 10
        a"

    [ $# -eq 0 ] &&
        echo "${USAGE}" ||
            printf "%x\n" "$1"
}

hex2dec()
{
    local USAGE="convert hex to decimal  equivalent

    Param:
        hex - hex to be converted

    Output:
        \$ hex2dec a
        10

        \$ hex2dec 0x0a
        10"

    [ $# -eq 0 ] &&
        echo "${USAGE}" ||
            echo $((0x${1#0x}))
}

dec2bin() { echo "obase=2;$1" | bc; }
bin2dec() { echo $((2#$1)); }

hex2bin()
{
	local bin
	local i

	for i in $*; do
		bin=$(echo "obase=2;ibase=16;$(echo $i | tr a-f A-F)" | bc)
		echo -n "$bin "
	done
	echo
}

## char and strings

isalnum() 
{
   local USAGE="determines whether string or char is alphanumeric.
    Param:
        string or char - return true or false.
    
    Output:
        \$ isalnum a
        \$ echo \$? 
        0
    "
    [ $# -eq 0 ] && echo -e "${USAGE}" || 
    echo "$1" | grep -Eqw '^[0-9A-Za-z]+$' 
}
isalpha() { echo "$1" | grep -Eqw '^[A-Za-z]+$'; }
#isascii() {}
#isblank() {}
#iscntrl() {}
isdigit() { echo "$1" | grep -Eqw '^[0-9]+$'; }
#isgraph() {}
islower() { echo "$1" | grep -Eqw '^[a-z]+$'; }
isprint()
{
	# nao ta rolando
	local i

	for i in $(str2hex -0x "$1" | sed 's/\(....\)/\1 /g'); do
		[ $(($i)) -ge 32 -a $(($i)) -le 127 ] || return 1
	done
	return 0
}
#ispunct() {}
#isspace() {}
isupper() { echo "$1" | grep -Eqw '^[A-Z]+$'; }
isxdigit() { echo "$1" | grep -Eqw '^[0-9A-Fa-f]+$'; }

dec2asc() { echo -e $(printf "\\\x%x" $1); }
asc2dec() { printf "%d\n" "'$1"; }

str2hex()
{
    local USAGE="Converts a string to hex bytes equivalent to each character (hex string).
        Param:
            -x  :    Output bytes spaced and not prefixed with '\x'.
            -0x :    Output bytes spaced and prefixed with '0x'.
            -c  :    Bytes array in C language style.
            -s  :    Output bytes not spaced and inital prefixed '0x'.
            
            string - converting string
            
        Output:
        \$ str2hex 'Fernando'
        46 65 72 6e 61 6e 64 6f

        \$ str2hex -x 'Fernando'
        \\\x46\\\x65\\\x72\\\x6e\\\x61\\\x6e\\\x64\\\x6f

        \$ str2hex -0x 'Fernado'
        0x46 0x65 0x72 0x6e 0x61 0x6e 0x64 0x6f

        \$ str2hex -s 'Fernando'
        0x4665726e616e646f\n"
    [ $# -eq 0 ] && { 
        echo -e "${USAGE}"
    }

	case "$1" in
		"-s") 
			echo -n "$2" | hexdump -ve '/1 "%02x"' | sed 's/^/0x/' 
			echo
			;;
		"-x")
			echo -n "$2" | hexdump -ve '/1 "%02x"' | sed 's/../\\x&/g'
			echo
			;;
		"-0x")
			echo -n "$2" | hexdump -ve '/1 "0x%02x "' | sed 's/\(.*\) /\1/'
			echo
			;;
		"-c")
			echo -n '{'
			echo -n "$2" | hexdump -ve '/1 "0x%02x, "' | sed 's/\(.*\), /\1/'
			echo '}'
			;;
		*)
			echo -n "$1" | hexdump -ve '/1 "%02x "' | sed 's/\(.*\) /\1/'
			echo
			;;
	esac
}

str2hexr()
{
	case "$1" in
		"-x" | "-0x" | "-c" | "-s")
			str2hex $1 "$(echo "$2" | rev)"
			;;
		*)
			str2hex "$(echo "$1" | rev)"
			;;
	esac
}

hex2str()
{
	local hex
	local str
	local i

	hex=$(echo $1 | sed 's/\(0x\|\\x\| \|{\|}\|,\)//g')

	# insert a space each two chars
	hex=$(echo $hex | sed 's/../& /g')

	# prefix with \x, needed by echo
	for i in $hex; do
		str="$str\\x$i"
	done

	echo -e $str
}

urlencode() {

    local USAGE="USAGE:
    hexencode 'string'
    Based on the ascii table will encode characters such as
    <> {} among others converting to 3e%% 3c%% ....

    $ hexencode '<script> alert(1);</script>'
    %%3cscript%%3e%%20alert(1)%%3b%%7b%%7d%%3c%%2fscript%%3e
    $ hexencode '\${var}'
    %%24(document)\n"
    # acredite nunca havia visto este post
    # http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
    # 
    local STRING="$@"
    local NSTRING=""
    local CHARLIST="\"\'\$\%\&\,\\\;\/:<>^\`\{\}\|"

    [ ! -z "${STRING}" ] && {
        for POS in $( seq 0 $((${#STRING}-1)) )
        do
            CHAR="${STRING:${POS}:1}"
            case "${CHAR}" in 
                [${CHARLIST}])
                    NSTRING="${NSTRING}%$(str2hex "${CHAR}")"
                ;;
                *)
                    NSTRING="${NSTRING}${STRING:${POS}:1}"
                ;;
            esac
        done
    } || printf "${USAGE}"
    echo ${NSTRING} | sed 's/ /%20/g'
}

charcal()
{
	local char
	local chars
	local res
	local i

	case $2 in
		+|-)
			for i in $(echo "$1" | sed 's/./& /g'); do
				char=$(asc2dec $i)
				res=$(($char $2 $3))
				echo -n $(dec2asc $res)
			done
			echo
		;;
		'*')
			for (( i=0; i<$3; i++ )); do
				res="$res$1"
			done
			echo $res
		;;
	esac
}

asciitable()
{
	echo -en \
	"Dec Hex    Dec Hex    Dec Hex  Dec Hex  Dec Hex  Dec Hex   Dec Hex   Dec Hex\n\
  0 00 NUL  16 10 DLE  32 20    48 30 0  64 40 @  80 50 P   96 60 \`  112 70 p\n\
  1 01 SOH  17 11 DC1  33 21 !  49 31 1  65 41 A  81 51 Q   97 61 a  113 71 q\n\
  2 02 STX  18 12 DC2  34 22 \"  50 32 2  66 42 B  82 52 R   98 62 b  114 72 r\n\
  3 03 ETX  19 13 DC3  35 23 #  51 33 3  67 43 C  83 53 S   99 63 c  115 73 s\n\
  4 04 EOT  20 14 DC4  36 24 $  52 34 4  68 44 D  84 54 T  100 64 d  116 74 t\n\
  5 05 ENQ  21 15 NAK  37 25 %  53 35 5  69 45 E  85 55 U  101 65 e  117 75 u\n\
  6 06 ACK  22 16 SYN  38 26 &  54 36 6  70 46 F  86 56 V  102 66 f  118 76 v\n\
  7 07 BEL  23 17 ETB  39 27 '  55 37 7  71 47 G  87 57 W  103 67 g  119 77 w\n\
  8 08 BS   24 18 CAN  40 28 (  56 38 8  72 48 H  88 58 X  104 68 h  120 78 x\n\
  9 09 HT   25 19 EM   41 29 )  57 39 9  73 49 I  89 59 Y  105 69 i  121 79 y\n\
 10 0A LF   26 1A SUB  42 2A *  58 3A :  74 4A J  90 5A Z  106 6A j  122 7A z\n\
 11 0B VT   27 1B ESC  43 2B +  59 3B ;  75 4B K  91 5B [  107 6B k  123 7B {\n\
 12 0C FF   28 1C FS   44 2C ,  60 3C <  76 4C L  92 5C \\  108 6C l  124 7C |\n\
 13 0D CR   29 1D GS   45 2D -  61 3D =  77 4D M  93 5D ]  109 6D m  125 7D }\n\
 14 0E SO   30 1E RS   46 2E .  62 3E >  78 4E N  94 5E ^  110 6E n  126 7E ~\n\
 15 0F SI   31 1F US   47 2F /  63 3F ?  79 4F O  95 5F _  111 6F o  127 7F DEL\n"
}

utf8table()
{
	echo -en \
"Hex      Hex      Hex      Hex      Hex      Hex      Hex      Hex\n\
c2 a0    c2 ac ¬  c2 b8 ¸  c3 84 Ä  c3 90 Ð  c3 9c Ü  c3 a8 è  c3 b4 ô\n\
c2 a1 ¡  c2 ad ­  c2 b9 ¹  c3 85 Å  c3 91 Ñ  c3 9d Ý  c3 a9 é  c3 b5 õ\n\
c2 a2 ¢  c2 ae ®  c2 ba º  c3 86 Æ  c3 92 Ò  c3 9e Þ  c3 aa ê  c3 b6 ö\n\
c2 a3 £  c2 af ¯  c2 bb »  c3 87 Ç  c3 93 Ó  c3 9f ß  c3 ab ë  c3 b7 ÷\n\
c2 a4 ¤  c2 b0 °  c2 bc ¼  c3 88 È  c3 94 Ô  c3 a0 à  c3 ac ì  c3 b8 ø\n\
c2 a5 ¥  c2 b1 ±  c2 bd ½  c3 89 É  c3 95 Õ  c3 a1 á  c3 ad í  c3 b9 ù\n\
c2 a6 ¦  c2 b2 ²  c2 be ¾  c3 8a Ê  c3 96 Ö  c3 a2 â  c3 ae î  c3 ba ú\n\
c2 a7 §  c2 b3 ³  c2 bf ¿  c3 8b Ë  c3 97 ×  c3 a3 ã  c3 af ï  c3 bb û\n\
c2 a8 ¨  c2 b4 ´  c3 80 À  c3 8c Ì  c3 98 Ø  c3 a4 ä  c3 b0 ð  c3 bc ü\n\
c2 a9 ©  c2 b5 µ  c3 81 Á  c3 8d Í  c3 99 Ù  c3 a5 å  c3 b1 ñ  c3 bd ý\n\
c2 aa ª  c2 b6 ¶  c3 82 Â  c3 8e Î  c3 9a Ú  c3 a6 æ  c3 b2 ò  c3 be þ\n\
c2 ab «  c2 b7 ·  c3 83 Ã  c3 8f Ï  c3 9b Û  c3 a7 ç  c3 b3 ó  c3 bf ÿ\n"
}

## crypto

unbase64() { echo $1 | base64 -d; }

md5()
{
	test -e $1 && \
		md5sum < "$1" | cut -d' ' -f1 \
	|| \
		echo -n "$1" | md5sum | cut -d' ' -f1
}

unmd5()
{
	local r=""
        local s1="http://md5crack.com/crackmd5.php"
        local s2="http://www.tobtu.com/md5.php?h=$1"

	# adicionado site tobtu.com, md5crack consta fora do ar - 11-12-12
        r="$( wget -q --timeout=30 "${s2}" -O - |
         grep -E "([a-f0-9]){32}" |
         cut -d':' -f3  )"

        [ -z "${r}" ] && r="$( wget -q --timeout=30 --post-data="term=$1" "${s1}" -O - |
         grep 'Found:'  |
         sed 's/.*md5("\(.*\)").*<\/div>/\1/' )"

        echo "${r}"
}

rot()
{
	local n

	test $# -eq 2 || return 1

	# n recebe o caractere do alfabeto correspondente
	n=$(echo -e \\x$(dec2hex $(echo -e $((97+$1)))))

	# rot com o tr
	echo $2 | tr a-z $n-za-z | tr A-Z ${n^^}-ZA-Z
}

rotall()
{
	local i

	test -n "$1" || return 1

	for i in {1..25}; do
		echo "ROT$i $(rot $i "$1")"
	done
}

alias rot5='rot 5'
alias rot13='rot 13'
alias rot18='rot 18'
alias rot47='rot 47'

strxor()
{
	local str
	local xored
	local i

	# $2 is the string and $1 is the xor key
	str=$(str2hex "$2")

	for i in $str; do
		xored="$xored $(dec2hex $((0x$i^$1)))"
	done

	hex2str "$xored"
}

keycheck()
{
	diff <(ssh-keygen -y -f "$1") <(cut -d' ' -f1,2 "$2") >/dev/null && echo \
	'keys match!' || echo 'keys does not match! :('
}

## networking

ip2bin()
{
	local i
	for i in $(echo "$1" | tr . ' '); do
		printf "%.8d." $(dec2bin $i)
	done | sed "s/.$/\\n/"
}

bin2ip()
{
	local i
	for i in $(echo "$1" | tr . ' '); do
		printf "%d." $(bin2dec $i)
	done | sed "s/.$/\\n/"
}

ip2geo()
{
	wget -q -T 30 "http://xml.utrace.de/?query=$1" -O - |
	 sed -e '4d; s/<[^>]*>//g; s/\t//g; /^$/d' |
	 tr \\n ' '
	 echo
}

myip() {	wget -q -T 10 'www.mentebinaria.com.br/ext/ip.php' -O -; echo; }

## social engineering

websearch() 
{
    local USAGE="USAGE:\nwebsearch <OPTIONS>
    -t|--type\t\t mail,file,phone,free one type is required
    -p|--to-page\t Number of pages OPTIONAL
    -d|--domain\t\t Domain Name or IpAddress is required
    -e|--file-ext\t Extension for query
    -s|--string\t\t parameter needed to free type and optional for others \n

    Mode:
    websearch -t file -e txt -d mentebinaria.com.br -p 2
    [ file ] IN mentebinaria.com.br txt
    [+] 0
    [+] 10
    [+] 20
    =============================================
    mentebinaria.com.br/artigos/0x0a/gamevista.txt
    mentebinaria.com.br/artigos/0x0b/virtlinux.txt
    mentebinaria.com.br/artigos/0x0d/altexe.txt\n\n"

    local i                     # count for() pagination
    local TYPE                  # type {mail,file,phone...}
    local DOMAIN                # domainame
    local TOPAGE=50             # set default pagination 
    local TMP="$(mktemp)"       # tmp file, store search
    local AGENT="Mozilla/5.0"   # user agent browser default
    local SEARCH                # variable to store rearch and submit google page
    local EXTENSION             # variable to store filetype as to search for file
    local EXTRACT               # variable with regular expression to extract data/information
    local STRING=""             # 
    local DOWNLOAD=0            # set donwload all file - default no

    # run param
    while (( $# )) 
    do
        case $1 in
            --download)
                DOWNLOAD=1
            ;;
            -t|--type)
                shift
                TYPE="$1"
            ;;
            -p|--to-page)
                shift
                isdigit $1
                test $? -eq 0 && TOPAGE=$(echo 10*$1 | bc ) || TOPAGE=50
            ;;
            -d|--domain)
                shift 
                DOMAIN="$1"
            ;;
            -s|--string)
                shift 
                [ -z "$1" ] && STRING="" || STRING="intext:$1"
            ;;
            -e|--file-ext)
                shift
                EXTENSION="$1"
            ;;
        esac
        shift
    done

    [ ! -z "${TYPE}" -a ! -z "${DOMAIN}" -o ! -z "${STRING}" ] && {

            [ "${TYPE}" == "mail" ] && {
                SEARCH="%22@${DOMAIN}%22"
    		    EXTRACT="sed -e 's/<[^>]*>//g' | 
                        grep -Ewo '([A-Za-z0-9_\.\-]){1,}\@${DOMAIN}' "
                } 

            [ "${TYPE}" == "file" -a ! -z "${EXTENSION}" ] && {
                SEARCH="site:${DOMAIN}%20filetype:${EXTENSION}%20${STRING}" 
                EXTRACT="tr '<' '\n' | 
                        grep -Ewo 'a href=\".*' | 
                        grep -Ev \"(google|search)\" | 
                        sed 's/a href=\"//g;s/&amp;sa//g' | 
                        grep '/url' | 
                        cut -d'=' -f2"
                }

            [ "${TYPE}" == "phone" ] && {
                SEARCH="site:${DOMAIN}%20(contato|faleconosco|telefone|telephone|phone|contact)"
                EXTRACT="grep -Ewo '(\(([0xx|0-9]){2,3}\)|([0-9]){2,3}).([0-9]){3,4}.([0-9]){4,5}' "
                }

            # free     
            [ "${TYPE}" == "free" -a ! -z "${STRING}" ] && {
                SEARCH="$(echo "${STRING}"|sed 's/^intext://')"
                EXTRACT="tr '<' '\n' | 
                        grep -Ewo 'a href=\".*' | 
                        grep -Ev \"(google|search)\" | 
                        sed 's/a href=\"//g;s/&amp;sa//g' | 
                        grep '/url' | 
                        cut -d'=' -f2"
                } 

        #### 

        echo "[ ${TYPE} ] IN ${DOMAIN} ${EXTENSION}"
        
	    for (( i=0 ; i<=${TOPAGE} ; i+=10 ))
	    do
		    echo "[+] ${i}"
		    wget -q -T 30 -U "${AGENT}" -O - \
                "http://www.google.com.br/search?q=${SEARCH}&btnG=&start=${i}" &>> ${TMP}
	    done
        
	    echo "============================================="

        [ ${DOWNLOAD} -eq 1 -a ${TYPE} == 'file' ] && {
            # tmp file store list
            LISTTMP=$(mktemp)
            # directory does not exist create it
            [ ! -d "${DOMAIN}" ] && mkdir "${DOMAIN}"
            # 
            cat ${TMP} | eval ${EXTRACT} | sort -u > ${LISTTMP}
            echo "Iniciando Download de $( cat ${LISTTMP} | wc -l ) Arquivos"
            # if elements exist - download
            [ $( wc -l ${LISTTMP} | cut -d" " -f1 ) -gt 0 ] && wget -P "${DOMAIN}" -i ${LISTTMP} &>>/dev/null
            [ $? -eq 0 ] && echo "Download feito em ${DOMAIN}"
            rm -rf ${LISTTMP}
        } || {
            # just list on then screen
            cat ${TMP} | eval ${EXTRACT} | sort -u
        }
        
        rm -rf ${TMP}
    } || printf "${USAGE}"

}

## reverse engineering

dumpmem()
{
	local stack_addr=$(grep -m 1 "$1" /proc/$2/maps |
	 cut -d' ' -f1 | sed 's/^/0x/; s/-/ 0x/')

	test -n "$stack_addr" && \
	echo "dump memory "$3" $stack_addr" | gdb --pid $2 &> /dev/null
}

alias dumpstack='dumpmem stack'
alias dumpheap='dumpmem heap'

asmgrep() { objdump -d "$2" | grep --color -C 4 -E "$1"; }

asminfo()
{
	local ins=${1,,}

	checkdir

	if test -s $hf_cache/$ins.txt; then
		cat $hf_cache/$ins.txt
	else
		wget -q faydoc.tripod.com/cpu/$ins.htm -O - |
		 html2text |
		 sed -n '/^===.*/,$p' |
		 sed 's/^===.*/'${ins^^}'/' | tr _ ' ' |
		 tee -a $hf_cache/$ins.txt
	fi

	test -s $hf_cache/$ins.txt || rm -f $hf_cache/$ins.txt
}

sc2asm()
{
	local mode=32
	local in="$1"

	[ $1 = '-m' ] && mode=$2 in="$3"

	sc=$(echo "$in" | sed 's/\\x/ /g')
	echo "$sc" | udcli -$mode -x -noff -nohex | sed 's/^ //'
}

asm2sc()
{
	local obj=$(mktemp)
	local fmt=elf32
	local in="$1"

	[ $1 = "-f" ] && fmt=$2 in="$3"

	nasm -f $fmt -o $obj $in 

	objdump -M intel -D $obj |
	 tr -d \\t |
	 sed -nr 's/^.*:(([0-9a-f]{2} )*).*$/\1/p' | 
	 tr -d \\n |
	 sed 's/\(..\) /\\x\1/g'

	echo
	rm -f $obj
}

## calc

xor() { echo $(($1^$2)); }
shl() { echo $(($1<<$2)); }
shr() { echo $(($1>>$2)); }
pow() { echo $(($1**$2)); }

hexcalc()
{
	test $# -eq 3 || return 1

	echo -n 0x
	dec2hex $((0x${1#0x} $2 0x${3#0x}))
}

## config

intel()
{
	local	GDBINIT="$HOME/.gdbinit"

	if [ "$1" == "on" ]; then
		grep -s 'disassembly-flavor' "$GDBINIT" &> /dev/null || \
		 echo "set disassembly-flavor intel" >> "$GDBINIT"
		alias gdb='gdb -q'
		alias objdump='objdump -M intel-mnemonics'
	elif [ "$1" == "off" ]; then
		sed -i 's/set disassembly-flavor intel//' "$GDBINIT"
		unalias objdump
		unalias gdb
	fi
}

# other
raffle()
{
	local i
	local interval=3
	test -n "$3" && interval=$3
	for i in $(seq $1 $2 | sort -R); do
		echo $i
		sleep $interval;
	done
}

matrix()
{
	echo -e "\e[32m";
	while :; do
		printf '%*c' $(($RANDOM % 30)) $(($RANDOM % 2));
	done
}

bkp() { cp "$1"{,.$(date +%Y%m%d)}; }
