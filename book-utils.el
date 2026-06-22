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

    (my/book-stamp-updated-today)
    
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
  "Add a tag to a record"
  (interactive)
  (my/book-tag-operate "--add" "Add Tag: "))

(define-key csv-mode-map (kbd "C-c t") 'my/book-tag-add)

;;; my/book-tag-remove

(defun my/book-tag-remove ()
  "Remove a tag from a record"
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

(defun my/book-goto-field (&optional field-name)
  "Jump to the column for FIELD-NAME. If FIELD-NAME is omitted, interactively prompt the user via the minibuffer."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         (script-path "/home/dad84/Documents/2026/20260612-books-csv-code/get_csv_headers.py")
         (cmd-str (format "python3 %s %s" script-path csv-path))
         (raw-output (shell-command-to-string cmd-str))
         (fields (read (format "(%s)" raw-output)))
         ;; Use the passed field-name; if nil, prompt the user interactively
         (target-field (or field-name 
                           (completing-read "Go to field: " fields nil t)))
         (target-index (cl-position target-field fields :test #'string=)))
    
    (if (not target-index)
        (error "Field '%s' not found in schema" target-field)
      (beginning-of-line)
      (when (> target-index 0)
        (if (search-forward "," (line-end-position) t target-index)
            nil
          (message "Warning: This record doesn't seem to have all fields yet."))))))

(define-key csv-mode-map (kbd "C-c g") 'my/book-goto-field)

;;; my/book-paste-and-strip-commas

(defun my/book-paste-and-strip-commas ()
  "Get text from the clipboard, remove all commas, and insert it at point."
  (interactive)
  (let ((clipboard-text (gui-get-selection 'CLIPBOARD 'STRING)))
    (if (not clipboard-text)
        (user-error "Clipboard is empty")
      (let ((clean-text (replace-regexp-in-string "," "" clipboard-text)))
        (insert clean-text)
        (message "Pasted and stripped commas from title!")))))

(define-key csv-mode-map (kbd "C-c y") 'my/book-paste-and-strip-commas)

;;; my/book-help-workbench

(defun my/book-help-workbench ()
  "Dynamically scan Emacs memory for all interactive 'my/book-' commands,
displaying them along with their documentation and active keyboard shortcuts."
  (interactive)
  (let ((buf (get-buffer-create "*Book Workbench Help*"))
        (collected-funcs nil))
    
    ;; 1. Scan global symbol dictionary for functions matching prefix AND interactive status
    (mapatoms
     (lambda (sym)
       (when (and (commandp sym) ; Filters out non-interactive helper functions
                  (string-match-p "^my/book-" (symbol-name sym)))
         (push sym collected-funcs))))
    
    ;; Sort the functions alphabetically so the help buffer is easy to read
    (setq collected-funcs (sort collected-funcs #'string<))
    
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "==================================================\n")
        (insert "           EMACS WORKBENCH: LIVE HELP             \n")
        (insert "==================================================\n\n")
        
        ;; 2. Loop through our auto-detected command list
        (if (null collected-funcs)
            (insert "No interactive functions starting with 'my/book-' were found in memory.\n\n")
          (dolist (func collected-funcs)
            (let* ((doc (or (documentation func) "No documentation provided."))
                   ;; Look up active keybindings for this specific command symbol
                   (keys (where-is-internal func csv-mode-map t))
                   (key-str (if keys (key-description keys) "Unbound")))
              
              ;; Print command name and its shortcut right next to it
              (insert (format "• %s  [%s]\n" (symbol-name func) key-str))
              ;; Indent the documentation string cleanly
              (insert (format "  %s\n\n" (replace-regexp-in-string "\n" "\n  " doc))))))
        
        (insert "==================================================\n")
        (goto-char (point-min))
        (view-mode 1)))
    
    ;; 3. Pop it open on screen
    (pop-to-buffer buf)))

(define-key csv-mode-map (kbd "C-c h") 'my/book-help-workbench)

;;; my/book-lastRead-data-entry

(defun my/book-lastRead-date-entry ()
  "Interactively prompt for lastRead date.  t means today.  p means publication date.  Otherwise enter e.g. 2026 or 202601 or 20260101 and YYYYMMDD will be auto-completed."
  (interactive)
  (let* ((csv-path (buffer-file-name))
         (csv-buffer-name (buffer-name)) ; Save the exact name of your CSV buffer
         (py-script "/home/dad84/Documents/2026/20260612-books-csv-code/process_smart_date.py")
         
         ;; 1. Safely hop to the 'year' column using our upgraded hybrid function
         (starting-point (point))
         (_ (my/book-goto-field "year"))
         (year-start (point))
         (_ (if (search-forward "," (line-end-position) t) (backward-char 1)))
         (pub-year (string-trim (buffer-substring-no-properties year-start (point))))
         
         ;; 2. Return the cursor back to the user's working spot
         (_ (goto-char starting-point))
         
         ;; 3. Prompt user for shortcut input
         (user-input (completing-read "Enter Date shortcut/digits (t/p/198/1980): " 
                                      '("t" "p") nil nil))
         
         ;; 4. Call Python and separate standard output from error channel
         (cmd (format "python3 %s '%s' '%s'" py-script user-input pub-year))
         (output-buffer (generate-new-buffer " *book-date-temp*")))
    
    (unwind-protect
        ;; Run the command, channeling errors cleanly
        (let ((exit-code (shell-command cmd output-buffer output-buffer)))
          (with-current-buffer output-buffer
            (let ((result-text (string-trim (buffer-string))))
              (if (/= exit-code 0)
                  ;; If Python exited with an error code (sys.exit(1)), crash gracefully here
                  (error "%s" result-text)
                
                ;; 5. FIX: Explicitly shift focus back to your actual CSV data buffer
                (set-buffer csv-buffer-name)
                
                ;; 6. Success! Jump to 'lastRead' and insert the stamped date
                (my/book-goto-field "lastRead")
                (let ((field-start (point)))
                  (if (search-forward "," (line-end-position) t)
                      (backward-char 1))
                  (delete-region field-start (point))
                  (insert result-text)
                  (message "Stamped: %s" result-text))))))
      ;; Clean up our temporary execution buffer behind the scenes
      (kill-buffer output-buffer))))

(define-key csv-mode-map (kbd "C-c d") 'my/book-lastRead-date-entry)
