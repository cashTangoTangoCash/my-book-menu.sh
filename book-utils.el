;; book-utils.el - Project-local functions
;;; my/book-stamp-updated-today

(defun my/book-stamp-updated-today ()
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

(define-key csv-mode-map (kbd "C-c u") 'my/book-stamp-updated-today)

;;; my/book-stamp-read-today

(defun my/book-stamp-read-today ()
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

(define-key csv-mode-map (kbd "C-c d") 'my/book-stamp-read-today)

;;; my/book-insert-new-record

(defun my/book-insert-new-record ()
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

    ;; TWEAK: Hop across the first comma to land directly in the second field (title)
    (when (search-forward "," (line-end-position) t 1)
      ;; Point is now placed exactly after the first comma. Ready to type!
      nil)
    
    (message "New record ready with ID assigned.")))

(define-key csv-mode-map (kbd "C-c n") 'my/book-insert-new-record)

;;; my/book-edit-comment-indirect

(defun my/book-edit-comment-indirect ()
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

(define-key csv-mode-map (kbd "C-c c") 'my/book-edit-comment-indirect)

;;; my/book-toggle-queue

(defun my/book-toggle-queue ()
  "Toggle the 'inQueue' field between 0 and 1."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         (raw-output (shell-command-to-string 
                      (format "python3 /home/dad84/Documents/2026/20260612-books-csv-code/get_column_index.py %s 'inQueue'" csv-path)))
         (col-index (string-to-number raw-output)))
    
    (if (< col-index 0)
        (error "Could not find 'inQueue' column!")
      
      (save-excursion
        (beginning-of-line)
        ;; Precision skip to the correct column
        (dotimes (i col-index)
          (search-forward "," (line-end-position) t))
        
        (let ((start (point)))
          ;; Identify cell end
          (if (search-forward "," (line-end-position) t)
              (backward-char 1))
          
          (let* ((current-val (buffer-substring-no-properties start (point)))
                 ;; Toggle Logic: If it's "1", make it "0". Everything else becomes "1".
                 (new-val (if (string= current-val "1") "0" "1")))
            (delete-region start (point))
            (insert new-val))))
      (message "inQueue field toggled!"))))

(define-key csv-mode-map (kbd "C-c q") 'my/book-toggle-queue)

;;; my/book-tag-add 

(defun my/book-tag-add ()
  (interactive)
  (my/book-tag-operate "--add" "Add Tag: "))

(define-key csv-mode-map (kbd "C-c t") 'my/book-tag-add)

;;; my/book-tag-remove

(defun my/book-tag-remove ()
  (interactive)
  (my/book-tag-operate "--remove" "Remove Tag: "))

(define-key csv-mode-map (kbd "C-c r") 'my/book-tag-remove)

;;; my/book-tag-operate

(defun my/book-tag-operate (action prompt)
  "Save buffer, then call python to add/remove tags for the current row."
  ;; 1. CRITICAL: Save current edits (like the Title) so Python can see them
  (save-buffer)
  
  (let* ((script-path "/home/dad84/Documents/2026/20260612-books-csv-code/tag_manager.py")
         (csv-path (buffer-file-name))
         (row-id (save-excursion 
                   (beginning-of-line)
                   ;; This regex looks for the ID at the very start of the line
                   (if (looking-at "\\([^,]+\\),") 
                       (match-string 1)
                     (error "Could not find ID at start of line. Did you run sanitize-ids?"))))
         ;; Use python to get the menu of existing tags
         (raw-tags (shell-command-to-string (format "python3 %s %s --list" script-path csv-path)))
         (tag-list (split-string (string-trim raw-tags) "|"))
         (chosen-tag (completing-read prompt tag-list)))

    (unless (string-empty-p chosen-tag)
      (let ((exit-code (shell-command 
                        (format "python3 %s %s %s %s --id %s" 
                                script-path 
                                (shell-quote-argument csv-path)
                                action
                                (shell-quote-argument chosen-tag) 
                                (shell-quote-argument row-id)))))
        (if (zerop exit-code)
            (progn 
              ;; Pull the changes Python made back into Emacs
              (revert-buffer t t) 
              (message "Tag operation successful."))
          (error "Python script failed with exit code %d" exit-code))))))

;;; my/book-toggle-hardcopy-inventory

(defun my/book-toggle-hardcopy-inventory ()
  "Toggle the 'hardcopy' field between 0 and 1 - take a book in and out of inventory"
  (interactive)
  (let* ((csv-path (buffer-file-name))
         (raw-output (shell-command-to-string 
                      (format "python3 /home/dad84/Documents/2026/20260612-books-csv-code/get_column_index.py %s 'hardcopy'" csv-path)))
         (col-index (string-to-number raw-output)))
    
    (if (< col-index 0)
        (error "Could not find 'hardcopy' column!")
      
      (save-excursion
        (beginning-of-line)
        ;; Precision skip to the correct column
        (dotimes (i col-index)
          (search-forward "," (line-end-position) t))
        
        (let ((start (point)))
          ;; Identify cell end
          (if (search-forward "," (line-end-position) t)
              (backward-char 1))
          
          (let* ((current-val (buffer-substring-no-properties start (point)))
                 ;; Toggle Logic: If it's "1", make it "0". Everything else becomes "1".
                 (new-val (if (string= current-val "1") "0" "1")))
            (delete-region start (point))
            (insert new-val))))
      (message "hardcopy field toggled!"))))

(define-key csv-mode-map (kbd "C-c i") 'my/book-toggle-hardcopy-inventory)

;;; my/book-toggle-pcCopy-inventory

(defun my/book-toggle-pcCopy-inventory ()
  "Toggle the 'pcCopy' field between 0 and 1 - take a book in and out of digital copy inventory"
  (interactive)
  (let* ((csv-path (buffer-file-name))
         (raw-output (shell-command-to-string 
                      (format "python3 /home/dad84/Documents/2026/20260612-books-csv-code/get_column_index.py %s 'pcCopy'" csv-path)))
         (col-index (string-to-number raw-output)))
    
    (if (< col-index 0)
        (error "Could not find 'pcCopy' column!")
      
      (save-excursion
        (beginning-of-line)
        ;; Precision skip to the correct column
        (dotimes (i col-index)
          (search-forward "," (line-end-position) t))
        
        (let ((start (point)))
          ;; Identify cell end
          (if (search-forward "," (line-end-position) t)
              (backward-char 1))
          
          (let* ((current-val (buffer-substring-no-properties start (point)))
                 ;; Toggle Logic: If it's "1", make it "0". Everything else becomes "1".
                 (new-val (if (string= current-val "1") "0" "1")))
            (delete-region start (point))
            (insert new-val))))
      (message "pcCopy field toggled!"))))

(define-key csv-mode-map (kbd "C-c s") 'my/book-toggle-pcCopy-inventory)

;;; my/book-goto-field

(defun my/book-goto-field ()
  "Dynamically prompt for a field name using a Python helper, then jump to it."
  (interactive)
  (let* ((csv-path "/home/dad84/Documents/2026/20260612-books-csv-file/books.csv")
         (script-path "/home/dad84/Documents/2026/20260612-books-csv-code/get_csv_headers.py")
         
         ;; Run the python script and wrap its output in standard Lisp parentheses: ("id" "title" ...)
         (cmd-str (format "python3 %s %s" script-path csv-path))
         (raw-output (shell-command-to-string cmd-str))
         (fields (read (format "(%s)" raw-output)))
         
         ;; Prompt the user with the dynamic list
         (field (completing-read "Go to field: " fields nil t))
         (target-index (cl-position field fields :test #'string=)))
    
    (if (not target-index)
        (error "Field not found in schema")
      ;; Move to start of line, then skip past N commas
      (move-beginning-of-line 1)
      (when (> target-index 0)
        (if (search-forward "," (line-end-position) t target-index)
            nil
          (message "Warning: This record doesn't seem to have all fields yet."))))))

(define-key csv-mode-map (kbd "C-c f") 'my/book-goto-field)
