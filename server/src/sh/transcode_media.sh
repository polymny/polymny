#!/bin/bash


# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-v] [-l LOGLEVEL] [FILE]...
Do stuff with FILE and write the result to standard output. With no FILE
or when FILE is -, read standard input.

    -h          display this help and exit
    -f OUTFILE  write the result to OUTFILE instead of standard output.
EOF
}

# Initialize our own variables:
loglevel="fatal"

OPTIND=1
# Resetting OPTIND is necessary if getopts was used previously in the script.
# It is a good idea to make OPTIND local if you process options in a function.

while getopts hl: opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        l)  loglevel=$OPTARG
            ;;
        *)
            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"   # Discard the options and sentinel --

# Everything that's left in "$@" is a non-option.  In our case, a FILE to process.
#printf 'verbose=<%d>\noutput_file=<%s>\nLeftovers:\n' "$verbose" "$output_file"

printf 'loglevel=<%s>\n' $loglevel
printf '<%s>\n' "$@"


INPUT_PATH=$1
OUTPUT_PATH=$2

DETECT_AUDIO=$(ffprobe -hide_banner -print_format json -show_streams -select_streams a $INPUT_PATH |\
jq '.[] | length')

if [ $DETECT_AUDIO = 0 ];
then
    printf  'no audio track\n';
fi


CMD="ffmpeg \
-nostats \
-progress /tmp/progress.log \
-loglevel $loglevel \
-hide_banner -y \
-i $INPUT_PATH "

if [ $DETECT_AUDIO = 0 ]; then
    CMD+="-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 ";
fi

CMD+="-profile:v main -pix_fmt yuv420p \
-level 3.1 \
-ar 48000 -ab 128k \
-vcodec libx264 -preset fast -tune zerolatency \
-b:v 5M \
-acodec aac \
-s hd1080 \
-r 25 "
if [ $DETECT_AUDIO = 0 ]; then
    CMD+="-shortest "
fi

CMD+="$OUTPUT_PATH"

echo "$CMD"
$CMD
