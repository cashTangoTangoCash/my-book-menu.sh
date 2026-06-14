import csv
import sys
import argparse
import os

def handle_tags():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--add")
    parser.add_argument("--remove") # You added this - it's correct!
    parser.add_argument("--id")
    args = parser.parse_args()

    # 1. Load the data
    rows = []
    with open(args.csv_path, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    # 2. ACTION: List tags (for the Lisp menu)
    if args.list:
        all_tags = set()
        for row in rows:
            tags_val = row.get('tags', '') or ''
            tags = [t for t in tags_val.split('|') if t]
            all_tags.update(tags)
        print("|".join(sorted(list(all_tags))))
        return

    # 3. ACTION: Add or Remove (The "Heavy Lifting")
    if (args.add or args.remove) and args.id:
        target_id = args.id.strip()
        found = False

        for row in rows:
            if row['id'].strip() == target_id:
                found = True
                current_tags_raw = row.get('tags', '') or ''
                tags_list = [t for t in current_tags_raw.split('|') if t]

                if args.add:
                    new_tag = args.add.strip()
                    if new_tag not in tags_list:
                        tags_list.append(new_tag)
                
                if args.remove:
                    tag_to_remove = args.remove.strip()
                    if tag_to_remove in tags_list:
                        tags_list.remove(tag_to_remove)

                # Re-build the pipe string correctly
                if tags_list:
                    row['tags'] = "|" + "|".join(tags_list) + "|"
                else:
                    row['tags'] = "" # Keep it clean if no tags left
                break
        
        if found:
            temp_file = args.csv_path + ".tmp"
            with open(temp_file, 'w', newline='', encoding='utf-8') as f:
                # 'extrasaction=ignore' tells Python: 
                # "If you find a stray field (like None), just toss it out."
                writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
                writer.writeheader()
                writer.writerows(rows)
            os.replace(temp_file, args.csv_path)
        else:
            print(f"ID {target_id} not found", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    handle_tags()
