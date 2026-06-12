SELECT 	    
	    title,
	    "author-last-name",
	    "author-first-name", 
	    year, 
	    otherOwners,
	    "last-updated",
	    "last-read",
	    tags
FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
WHERE "acquisition-queue" = 1
ORDER BY 
      "last-updated" DESC NULLS LAST
