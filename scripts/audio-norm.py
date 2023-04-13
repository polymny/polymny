#!./.venv/bin/python
import argparse
import subprocess
import os
import re
from rich_argparse import RichHelpFormatter


def main(args: argparse.Namespace) -> None:
    """Normalize the audio of a file.

    Args:
        args (argparse.Namespace): Arguments.
    """

    filter = ("equalizer=f=1000:width_type=q:width=2:g=-6," +  # Equalize bass.
              "loudnorm=I=-16:LRA=11:TP=-2")  # Normalize audio.

    cmd = [
        'ffmpeg',
        '-y',
        '-i',
        args.input,
        '-c:v',
        'copy',
        '-af',
        filter,
        args.output
    ]

    process = subprocess.Popen(cmd,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT,
                               universal_newlines=True)

    # Print progress.
    total_bytes = os.stat(args.input).st_size
    for line in process.stdout:
        size = re.search(r'size= +(\d+)kB', line)
        if size:
            bytes_processed = int(size.group(1)) * 1000
            progress = bytes_processed / total_bytes
            print(f"\rProgress: {progress:7.2%}", end='')
    print("\rProgress: 100.00%", end='')


if __name__ == '__main__':

    # Parse arguments.
    parser = argparse.ArgumentParser(description="""
                                     Normalize the audio of a file.
                                     The output file will be overwritten if it already exists.""",
                                     formatter_class=RichHelpFormatter)
    parser.add_argument('--input',
                        '-i',
                        action='store',
                        dest='input',
                        required=True,
                        help='input file',
                        metavar='INPUT',
                        type=str)
    parser.add_argument('--output',
                        '-o',
                        action='store',
                        dest='output',
                        required=True,
                        help='output file',
                        metavar='OUTPUT',
                        type=str)
    args = parser.parse_args()

    # Run main.
    main(args)
