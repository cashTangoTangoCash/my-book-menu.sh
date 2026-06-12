SELECT 	    
	    title,
	    authorLastName,
	    authorFirstName, 
	    year, 
	    otherOwners,
	    lastUpdated,
	    lastRead,
	    tags
FROM read_csv_auto('/home/dad84/Documents/2026/20260612-books-csv-file/books.csv')
WHERE acquisitionQueue = 1
ORDER BY 
      lastUpdated DESC NULLS LAST
