#!./.venv/bin/python
import argparse
import subprocess
from rich_argparse import RichHelpFormatter


def main(args: argparse.Namespace) -> None:
    """Convert a PDF file to a PNG file.

    Args:
        args (argparse.Namespace): Arguments.
    """

    cmd = ['convert',
           '-density',
           args.density,
           '-colorspace',
           args.colorspace,
           '-resize',
           args.size,
           '-background',
           'white',
           '-gravity',
           'center',
           '-extent',
           args.size,
           args.input,
           args.output]
    
    subprocess.run(cmd)


if __name__ == '__main__':

    # Parse arguments.
    parser = argparse.ArgumentParser(description="""
                                     Convert a PDF file to a PNG file.
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
    parser.add_argument('--density',
                        '-d',
                        action='store',
                        dest='density',
                        required=True,
                        help='density',
                        metavar='DENSITY',
                        type=str)
    parser.add_argument('--colorspace',
                        '-c',
                        action='store',
                        dest='colorspace',
                        required=True,
                        help='colorspace',
                        metavar='COLORSPACE',
                        type=str)
    parser.add_argument('--size',
                        '-s',
                        action='store',
                        dest='size',
                        required=True,
                        help='size',
                        metavar='WIDTHxHEIGHT',
                        type=str)
    args = parser.parse_args()

    # Run main.
    main(args)
