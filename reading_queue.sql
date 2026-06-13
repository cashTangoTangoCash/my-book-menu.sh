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
WHERE 
    -- 1. Must be flagged for reading
    inQueue = 1
    
    -- 2. Must own at least one copy (digital OR physical)
    AND (pcCopy = 1 OR hardcopy = 1)

ORDER BY 
      lastUpdated DESC NULLS LAST
