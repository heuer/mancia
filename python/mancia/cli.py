#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
"""\
Command line interface for mancia.
"""
import sys
import argparse
from .converter import to_roff, to_rst


def main():
    parser = argparse.ArgumentParser(description='scdoc ')
    parser.add_argument('--format', choices=['roff', 'rst'], default='roff',
                        help='Output format (default: roff)')
    parser.add_argument('input', nargs='?', help='Input file (default: stdin)')
    args = parser.parse_args()
    if args.input:
        with open(args.input) as f:
            scdoc = f.read()
    else:
        scdoc = sys.stdin.read()
    try:
        print(to_roff(scdoc) if args.format == 'roff' else to_rst(scdoc))
    except Exception as ex:
        print(f'Error: {ex}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

