import csv
import os
import sys

def sanitize_csv_ids(csv_path):
    temp_file = csv_path + ".tmp"
    
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV file not found at {csv_path}")

    with open(csv_path, mode='r', newline='', encoding='utf-8') as fin:
        reader = csv.DictReader(fin)
        fieldnames = reader.fieldnames
        
        if 'id' not in fieldnames:
            raise KeyError("The CSV is missing the 'id' column header!")
            
        rows = list(reader)

    # --- THE AUDIT ---
    seen_ids = set()
    duplicates = []
    max_id = 0

    # First pass: find duplicates and establish the highest integer ID
    for row in rows:
        current_id_raw = row.get('id', '').strip()
        
        try:
            val = int(current_id_raw)
            # Track max for new assignments
            if val > max_id:
                max_id = val
            
            # Check for duplicates among valid integers
            if str(val) in seen_ids:
                duplicates.append(str(val))
            seen_ids.add(str(val))
            
        except ValueError:
            # If it's not an integer (like 'v1387'), we ignore it for now.
            # It will be caught and replaced in the Auto-Stamping logic.
            continue

    if duplicates:
        raise ValueError(f"Duplicate IDs found: {', '.join(set(duplicates))}. Fix in Emacs!")

    # --- THE REPAIR & AUTO-STAMPING LOGIC ---
    changes_made = 0
    for row in rows:
        current_id_raw = row.get('id', '').strip()
        
        is_valid_int = False
        try:
            if current_id_raw:
                int(current_id_raw)
                is_valid_int = True
        except ValueError:
            is_valid_int = False

        # If ID is missing, blank, or invalid (non-integer)...
        if not current_id_raw or not is_valid_int:
            max_id += 1
            old_val = current_id_raw if current_id_raw else "BLANK"
            row['id'] = str(max_id)
            changes_made += 1
            # Optional: print for your own log
            # print(f"Repairing ID: {old_val} -> {max_id}")

    # Write to disk if we added new IDs OR repaired corrupted ones
    if changes_made > 0:
        with open(temp_file, mode='w', newline='', encoding='utf-8') as fout:
            # 'extrasaction=ignore' tells Python: 
            # "If you find a stray field (like None), just toss it out."
            writer = csv.DictWriter(fout, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(rows)
        os.replace(temp_file, csv_path)
        print(f"Repaired/Stamped {changes_made} records with valid integer IDs.")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 sanitize_ids.py <csv_file>")
        sys.exit(1)
    try:
        sanitize_csv_ids(sys.argv[1])
        sys.exit(0) 
    except Exception as e:
        print(f"\n[INTEGRITY ERROR]: {e}", file=sys.stderr)
        sys.exit(1)
