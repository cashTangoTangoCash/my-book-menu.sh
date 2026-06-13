#!/usr/bin/bash

# typically, the user has created one or more new records and wants to give them ids.
# non-blank ids are necessary for other functions

cd /home/dad84/Documents/2026/20260612-books-csv-file/

CSV="/home/dad84/Documents/2026/20260612-books-csv-file/books.csv"

# make backup copy of csv file, as in some cases you are altering that file
cp "$CSV" "$CSV.bak"

# --- AUTONOMIC ID CHECK ---
echo "checking that record ids are valid..."
if python3 /home/dad84/Documents/2026/20260612-books-csv-code/sanitize_ids.py "$CSV"; then
    echo "SUCCESS: ID field check passed."
    echo "------------------------------------------------"
else
    echo "================================================"
    echo "  ABORTING: CSV Data Integrity Issue Detected!  "
    echo "  Check your headers or file permissions.       "
    echo "================================================"
    exit 1
fi
