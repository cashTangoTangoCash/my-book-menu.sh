#!/usr/bin/env python3
import csv
import sys

def get_headers(csv_path):
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            header = next(reader)
            # Print space-separated fields for Emacs to easily parse
            print(" ".join(f'"{field}"' for field in header))
    except (StopIteration, FileNotFoundError):
        print("") # Return empty on error

if __name__ == "__main__":
    if len(sys.argv) > 1:
        get_headers(sys.argv[1])
