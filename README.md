# my-book-menu.sh

Use Emacs and the terminal as a unified Terminal User Interface (TUI)
to interact with a simple CSV file to keep track of your library.

## The Problem

Heavyweight reference managers like Zotero are fantastic, but they are
a heavy lift for a user who only needs a tiny slice of their feature
set. My needs are much simpler: I want to keep track of books I own,
books I'm reading, and books I am interested in. I want to work
strictly in Emacs and the terminal, and I want my data to live in a
transparent, future-proof CSV file.

## Prerequisites

This system is built for **Linux** and relies on a few lightweight CLI utilities to generate reports and interfaces:
* **GNU Emacs** (Developed on 30.2)
* **DuckDB** (Handles backend SQL reporting on the CSV)
* **fzf** (Handles interactive fuzzy searching and tag selection)

## Usage

Run the main script from your terminal:

```bash
./my-book-menu.sh
```

You will be presented with the main action menu:

```bash
================================
    EMACS BOOK REPORTER        
================================
o) open the csv file of books in emacs for editing, & load your custom lisp functions for data entry
a) view acquisition queue - books you want to get a copy of on hand - either borrowed or purchased
r) view reading queue - books you have on hand and that you want to make time to read
d) show duplicates (same title and same author last name)
e) show duplicates (titles start the same way and one is longer than the other)
s) search the entire record with fzf
l) view 100 most recently read books
f) show a simple list of tags in order of decreasing frequency
t) choose one or more tags and see records having all chosen tags (AND)
*** m) use fzf to choose among additional functions
q) quit
```

(Note: Option `m` is a placeholder for future functions).

Most menu choices instantly compute a query behind the scenes using
DuckDB and output a clean text report into an Emacs buffer.

### CSV Schema Requirements

You must supply your own books.csv file. The scripts assume the
following first-row column headers (the scripts auto-populate the id
field):

```
id,title,authorLastName,authorFirstName,year,publisher,pcCopy,hardcopy,otherOwners,inQueue,lastUpdated,lastRead,tags,comment
```

(The scripts auto-populate the id field)

To conform to the multi-tag reporting logic, tags should be formatted using pipes as delimiters:

```
|oneTag|anotherTag|
```

### The Emacs Workbench

Choosing option `o` opens your database inside Emacs and automatically
loads custom Elisp utility functions. Your terminal scales down into a
convenient shortcut cheat sheet:

```
==================================================
       EMACS WORKBENCH: BOOK CSV              
==================================================
lisp tools have been loaded for: $CSV
these tools operate on the record at point in emacs

Helpful Shortcuts in CSV Mode:
C-c f  -> Move cursor to a field in the present record by choosing field name in minibuffer (book-goto-field)
C-c d  -> Stamp today's date in lastUpdated field of record at point (book-stamp-updated-today)
C-c r  -> Stamp today's date in lastRead field of record at point (book-stamp-read-today)
C-c n  -> Jump to bottom and insert new record (book-insert-new-record)
C-c c  -> edit comment (Capture Mode) - (book-edit-comment-indirect)
* Use C-c C-c to SAVE and EXIT capture
* Use C-c C-k to DISCARD changes
C-c q  -> add to, or remove from, (toggle) queue (0/1) - (book-toggle-queue)
C-c t  -> add a tag - (book-tag-add)
C-c r  -> remove a tag - (book-tag-remove)
C-c i  -> toggle hardcopy status - (book-toggle-hardcopy-inventory)
C-c s  -> toggle pcCopy status - (book-toggle-pcCopy-inventory)
==================================================
```

[!WARNING]

Hardcoded Paths: This is a personal hobby project. You will have to
open the shell scripts and .sql files to alter the hardcoded absolute
file paths to point to your actual local directory structures. If you
aren't sure how to do this, feed the scripts to a premier AI
chatbot—it can easily guide you through updating the paths.

## Development Status

2026-06-14: Structurally complete but minimally tested. I am using
this regularly on my live collection and will fix bugs organically as they
present themselves.

## How it was Developed

This script was built through an iterative dialogue with Gemini (free
version). For a detailed look at the logic, the alternative approaches
considered, and the evolution of the code, check the contents of the
chat/ folder in this repository.

(Note: This project borrows structural frameworks from my previous
Garmin and Movie TUI scripts, so the chat history starts somewhat in
the "middle" of the design story).

## License

See LICENSE file
