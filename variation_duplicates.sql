WITH normalized_books AS (
    SELECT 
        title AS original_title,
        COALESCE(authorLastName, 'Unknown') AS author,
        trim(regexp_replace(lower(title), '[^\w\s]', '', 'g')) AS clean_title
    FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
)
SELECT 
    b1.original_title AS shorter_title,
    b2.original_title AS longer_title,
    b1.author AS author
FROM normalized_books b1
JOIN normalized_books b2 
  -- Simple rule: The longer title must start with the shorter title + a space
  ON b2.clean_title LIKE b1.clean_title || ' %'
ORDER BY b1.author, b1.original_title;
