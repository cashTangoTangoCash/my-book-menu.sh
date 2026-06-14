-- tagged_books.sql
WITH book_list_tags AS (
    SELECT 
        title,
        authorLastName,
        tags,
        -- Turn '|math|interested|' into a clean SQL list ['math', 'interested']
        string_split(trim(tags, '|'), '|') AS current_book_tags
    FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
)
SELECT 
    title, 
    authorLastName, 
    tags
FROM book_list_tags
WHERE 
    -- 1. Split the exported Bash string into a list
    -- 2. Check if the book contains ALL elements of that list
    list_has_all(
        current_book_tags, 
        string_split(getenv('CHOSEN_TAGS'), ',')
    )
ORDER BY authorLastName, title;
