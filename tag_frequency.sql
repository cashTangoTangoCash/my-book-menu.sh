WITH split_tags AS (
    SELECT 
        -- 1. Remove the leading and trailing pipe characters
        -- 2. Split the remaining string by the pipe '|' delimiter into a list
        string_split(trim(tags, '|'), '|') AS tag_list
    FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
    WHERE tags IS NOT NULL AND tags != ''
),
flattened_tags AS (
    SELECT 
        -- 3. Explode the list so every single tag gets its own row
        unnest(tag_list) AS single_tag
    FROM split_tags
)
SELECT 
    single_tag AS tag,
    COUNT(*) AS frequency
FROM flattened_tags
-- 4. Clean up any accidental empty spaces around the tags
WHERE trim(single_tag) != ''
GROUP BY single_tag
ORDER BY frequency DESC, tag ASC;
