#!/usr/bin/env python3
import sys
from datetime import datetime

def compute_smart_date(user_input, pub_year):
    """
    Expand a human-entered shortcut or numeric shorthand into a YYYYMMDD date.
    
    Parameters:

    First parameter:
    user_input (str): 't', 'p', or numeric strings like '198', '1980', '198003'.
    't' means: return today's date
    'p' means: return the publication date
    Integer values are leading portions of the date on which you last read the book (lastRead field in .csv)

    Second Parameter:
    pub_year (str): The publication year.
    
    Returns:
    str: A validated 8-digit date string (YYYYMMDD).
    """
    user_input = user_input.strip().lower()
    pub_year = pub_year.strip() if pub_year else ""

    # Validate that pub_year is a 4-digit number if provided
    if pub_year and (len(pub_year) != 4 or not pub_year.isdigit()):
        raise ValueError(f"Invalid publication year format in CSV: '{pub_year}'")
    
    # 1. Today's Date
    if user_input == 't':
        return datetime.now().strftime("%Y%m%d")
        
    # 2. Publication Year
    if user_input == 'p':
        if pub_year:
            return f"{pub_year}0101"
        # Raise an error instead of defaulting to today's date
        raise ValueError("Cannot use shortcut 'p' because the 'year' field is blank for this record.")
        
    # Clean and isolate numeric input for shorthands
    digits = "".join([c for c in user_input if c.isdigit()])
    
    # Assign the target date string based on pattern matching
    final_date = ""
    if len(digits) == 3:      # Decade shorthand (e.g., 198 -> 19800101)
        final_date = f"{digits}00101"
    elif len(digits) == 4:    # Year shorthand (e.g., 1980 -> 19800101)
        final_date = f"{digits}0101"
    elif len(digits) == 6:    # Year + Month shorthand (e.g., 198003 -> 19800301)
        final_date = f"{digits}01"
    else:
        # Catch-all if the user types gibberish or an unsupported pattern
        raise ValueError(f"Unrecognized date shortcut pattern: '{user_input}'")

    # Time-travel check: Did they read it before it was published?
    if pub_year:
        read_year = int(final_date[:4])
        if read_year < int(pub_year):
            raise ValueError(f"Chronology Error: Read year ({read_year}) cannot be before publication year ({pub_year})")
        
    return final_date

if __name__ == "__main__":
    # Expects arguments: script.py [input] [publication_year]
    inp = sys.argv[1] if len(sys.argv) > 1 else "t"
    pyear = sys.argv[2] if len(sys.argv) > 2 else ""
    
    try:
        # Calculate the result
        result = compute_smart_date(inp, pyear)
        # Print clean output directly for Emacs to catch
        print(result, end="")
    except ValueError as e:
        # Catch our errors, write them to standard error, and exit cleanly
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
