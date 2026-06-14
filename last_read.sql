SELECT 
        title,
        authorLastName,
        authorFirstName, 
        year,
	pcCopy,
	hardcopy,
        lastUpdated,
        lastRead,
        tags,
	comment
FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
WHERE "lastRead" IS NOT NULL 
ORDER BY "lastRead" DESC
LIMIT 100;
