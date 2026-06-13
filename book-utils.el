;; book-utils.el - Project-local functions
;;; book-stamp-updated-today

(defun book-stamp-updated-today ()
  "Find the lastUpdated column dynamically and insert YYYYMMDD.  call this function from book csv file."
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

;;; book-stamp-read-today

(defun book-stamp-read-today ()
  "Find the lastRead column dynamically and insert YYYYMMDD.  call this function from book csv file."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         ;; Call the Python script and capture the index
         (col-index (string-to-number 
                     (shell-command-to-string 
                      (format "python3 /home/dad84/Documents/2026/20260612-books-csv-code/get_column_index.py %s 'lastRead'" csv-path)))))
    
    (if (< col-index 0)
        (error "Could not find 'lastRead' column in CSV header!")
      
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

(define-key csv-mode-map (kbd "C-c r") 'book-stamp-read-today)

;;; book-insert-new-record

(defun book-insert-new-record ()
  "Insert a new record template, save, and run external ID sanitization."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         (sanitize-script "/home/dad84/Documents/2026/20260612-books-csv-code/sanitize-ids.sh")
         (comma-count (string-to-number 
                       (shell-command-to-string 
                        (format "python3 -c \"import csv; print(len(next(csv.reader(open('%s')))) - 1)\"" csv-path)))))
    
    ;; 1. Prepare the template at the end of the file
    (save-excursion
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (insert (make-string comma-count ?,)))

    ;; 2. Save the buffer to disk so the bash script can see the new line
    (save-buffer)

    ;; 3. Call the bash wrapper to assign IDs
    (message "Sanitizing IDs...")
    (shell-command (format "bash %s" sanitize-script))

    ;; 4. Revert the buffer (ignore-auto and noconfirm) 
    ;; This pulls the ID-filled version back into Emacs
    (revert-buffer t t)

    ;; 5. Clean up: Move cursor to the end of the file to start typing
    (goto-char (point-max))

    ;; If the point is on an empty line at the end (due to our \n), 
    ;; move back to the previous line (our new record).
    (when (looking-back "\n" 1)
      (forward-line -1))
    
    (beginning-of-line)
    (message "New record ready with ID assigned.")))

(define-key csv-mode-map (kbd "C-c n") 'book-insert-new-record)

;;; book-edit-comment-indirect

(defun book-edit-comment-indirect ()
  "Jump to the comment column and trigger an indirect edit buffer."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         ;; Use your Python sensor to find the 'comment' column
         (col-index (string-to-number 
                     (shell-command-to-string 
                      (format "python3 /home/dad84/Documents/2026/20260612-books-csv-code/get_column_index.py %s 'comment'" csv-path)))))
  
    (if (< col-index 0)
        (error "Could not find 'comment' column!")
      
      (beginning-of-line)
      (dotimes (i col-index)
        (search-forward "," (line-end-position) t))
      
      ;; Identify the cell boundaries for edit-indirect
      (let ((start (point))
            (end (save-excursion 
                   (if (search-forward "," (line-end-position) t)
                       (1- (point))
                     (line-end-position)))))
        ;; The 'Capture' Magic
        (edit-indirect-region start end t)
        (message "Editing cell. C-c C-c to commit, C-c C-k to abort.")))))

(define-key csv-mode-map (kbd "C-c c") 'book-edit-comment-indirect)

