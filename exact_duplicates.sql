SELECT 
    title, 
    -- Grab the author if it exists, otherwise leave a placeholder
    COALESCE(authorLastName, 'Unknown') AS author,
    COUNT(*) AS occurrence_count
FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
GROUP BY title, authorLastName
HAVING COUNT(*) > 1
ORDER BY title;
