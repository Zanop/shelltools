#Intensity   0   1   2   3   4   5   6   7
#Normal  Black   Red Green   Yellow  Blue    Magenta Cyan    White
#Bright  Black   Red Green   Yellow  Blue    Magenta Cyan    White
CSI="\x1b["


function cprint {
    case $1  in
    'black')
        code='30m';;
    'red')
        code='31m';;
    'green')
        code='32m';;
    'yellow')
        code='33m';;
    'blue')
        code='34m';;
    'magenta')
        code='35m';;
    'cyan')
        code='36m';;
    'white')
        code='37m';;
    esac
    	echo -en "${CSI}${code}${2}${CSI}0m"
}
