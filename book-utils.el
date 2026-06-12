;; book-utils.el - Project-local functions
;;; book-stamp-today

(defun book-stamp-updated-today ()
  "Find the lastUpdated column dynamically and insert YYYYMMDD.  call it from book csv file."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         ;; Call the Python script and capture the index
         (col-index (string-to-number 
                     (shell-command-to-string 
                      (format "python3 /home/dad84/Documents/2026/20260612-books-csv-code/get_column_index.py %s 'lastUpdated'" csv-path)))))
    
    (if (< col-index 0)
        (error "Could not find 'lastUpdated' column in CSV header!")
      
      (save-excursion
        (beginning-of-line)
        ;; Move forward by the number of commas Python found
        (dotimes (i col-index)
          (search-forward "," (line-end-position) t))
        
        (let ((start (point)))
          (if (search-forward "," (line-end-position) t)
              (backward-char 1))
          (delete-region start (point))
          (insert (format-time-string "%Y%m%d"))))
      (message "Date stamped in column %d!" col-index))))

(define-key csv-mode-map (kbd "C-c d") 'book-stamp-updated-today)
