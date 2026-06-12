#!/usr/bin/bash

### define filepaths

WORKING_DIR="/home/dad84/Documents/2026/20260612-books-csv-code/"
FILE_DIR="/home/dad84/Documents/2026/20260612-books-csv-file/"
CSV_NAME="books.csv"
CSV="$FILE_DIR/$CSV_NAME"
REPORT="/tmp/book_report.txt"

cd "$WORKING_DIR" || exit 1

### make backup copy of csv file

cp "$CSV" "$CSV.bak"

### display a menu to the user
echo "================================"
echo "    EMACS BOOK REPORTER        "
echo "================================"
echo "o) open the csv file of books in emacs for editing, & load your custom lisp functions for data entry"
echo "a) view acquisition queue"
echo "r) view reading queue"
echo "d) show duplicates (same title)"
echo "s) search the entire record with fzf"
echo "h) view 100 most recently read books"
echo "m) use fzf to choose among additional functions"
echo "q) quit"
echo "--------------------------------"
read -p "Choose an option: " choice

case $choice in

### menu choice o: open the csv file of movies in emacs for editing, & load your custom lisp functions for data entry
    
  o)
    echo "=================================================="
    echo "           EMACS WORKBENCH: BOOK CSV              "
    echo "=================================================="
    echo "lisp tools have been loaded for: $CSV"
    echo "these tools operate on the record at point in emacs"
    echo ""
    echo "Helpful Shortcuts in CSV Mode:"
    echo "  C-c d  -> Stamp today's date in lastUpdated field of record at point (book-stamp-updated-today)"
    echo "***  C-c v  -> Increment View Count in record at point (book-increment-viewCount)"
    echo "***  C-c n  -> Jump to bottom and insert new record (book-insert-new-record)"
    echo "***  C-c c  -> edit comment (Capture Mode) - (book-edit-comment-indirect)"
    echo "            * Use C-c C-c to SAVE and EXIT capture"
    echo "            * Use C-c C-k to DISCARD changes"
    echo "***  C-c a  -> add to, or remove from, (toggle) aquire queue (0/1) - (book-toggle-acquire-queue)"
    echo "***  C-c q  -> add to, or remove from, (toggle) read queue (0/1) - (book-toggle-read-queue)"
    echo "***  C-c t  -> add a tag - (book-tag-add)"
    echo "***  C-c r  -> remove a tag - (book-tag-remove)"
    echo "***  C-c !  -> perform data cleanup on csv file - (book-full-cleanup)"    
    
    echo "=================================================="
    
    emacsclient -n "$CSV"

    # Tell Emacs to load a local lisp file containing lisp functions to use in editing movies csv file
    # We use realpath to make sure Emacs finds it regardless of where you are

    UTILS_PATH=$(realpath "book-utils.el")
    emacsclient -e "(load-file \"$UTILS_PATH\")"
    
    echo "Done. Emacs is ready for data entry."
    
    exit 0
  ;;


### menu choice a: duckdb query: acquisition queue
  
  a)
    REPORT_TITLE="    Acquisition Queue"	
    QUERY=".read acquisition_queue.sql"
  ;;

### menu choice r: duckdb query: reading queue
  
  r)
    REPORT_TITLE="    Reading Queue"	
    QUERY=".read reading_queue.sql"
  ;;

### menu choice d: duckdb query: duplicate records
  
  d)
    REPORT_TITLE="    Duplicate Records"	
    QUERY=".read duplicate-titles.sql"
    ;;

### menu choice s: select records in terminal via fzf - then form duckdb query from that selection set
  
  s)
    REPORT_TITLE="    Search the Entire Record with fzf"	

    # --multi allows you to select multiple movies with TAB

    # 1. We feed fzf the CSV (excluding the header for cleaner searching)
    # 2. We keep the whole line so fzf can search Title, Year, etc.
    SELECTIONS=$(tail -n +2 "$CSV" | fzf --exact --reverse --multi --header "TAB to select, ENTER to finish")

    if [ -n "$SELECTIONS" ]; then
        # 3. Extract the ID (the first column) from the selected lines
        # Assuming 'id' is the first column in your CSV
        ID_LIST=$(echo "$SELECTIONS" | cut -d',' -f1 | paste -sd "," -)
        
        # 4. The SQL is now dead simple: no math, just a direct ID match
        QUERY="SELECT * FROM read_csv_auto('$CSV') WHERE id IN ($ID_LIST);"
    
    fi
    ;;

### menu choice 5: duckdb query: 100 most recently viewed movies
  
  h)
    REPORT_TITLE="    100 Most Recently Read Books"	
    QUERY=".read last_read.sql"
    ;;
  
esac
### Execute DuckDB query, save report to /tmp, then open report in Emacs

# in any menu choice that does not generate a query, you have to exit before the script gets here
# in many menu choices, we have created a duckdb query.  now we generate a report via the query.

# line mode looks ok
echo "================================" > "$REPORT"
echo "$REPORT_TITLE" >> "$REPORT"
echo "================================" >> "$REPORT"
duckdb -c ".mode line" -c ".maxrows 0" -c "$QUERY" >> "$REPORT"

# Open the report in your current Emacs session
emacsclient -n "$REPORT"

echo "Report opened in Emacs buffer!"
