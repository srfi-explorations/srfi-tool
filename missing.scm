(import (scheme base)
        (scheme char)
        (scheme cxr)
        (scheme file)
        (scheme process-context)
        (scheme write)
        (chibi html-parser))

(cond-expand ((or chibi cyclone gauche sagittarius)
              (import (srfi 69) (srfi 132)))
             (chicken
              (import (srfi 69) (chicken sort)))
             (kawa
              (import (srfi 69) (srfi 95))))

(cond-expand ((or chicken kawa)
              (define (list-sort less? list) (sort list less?)))
             (else))

(define (disp . xs)
  (for-each display xs)
  (newline))

(define (string-first-char? ch string)
  (and (not (= 0 (string-length string)))
       (char=? ch (string-ref string 0))))

(define (assoc-get get key alist)
  (let ((pair (assoc key alist)))
    (if pair (get pair) #f)))

(define (sxml-for-each proc elem)
  (let walk ((elem elem))
    (cond ((not (pair? elem)) '())
          ((equal? '@ (car elem)) '())
          (else (proc elem)
                (for-each walk (cdr elem))))))

(define (sxml-attributes elem)
  (if (and (pair? elem)
           (pair? (cdr elem))
           (pair? (cadr elem))
           (equal? '@ (caadr elem)))
      (cdadr elem)
      '()))

(define (missing-a-names html-file)
  (let ((names (make-hash-table))
        (hrefs (make-hash-table)))
    (sxml-for-each
     (lambda (elem)
       (let ((attrs (sxml-attributes elem)))
         (let ((id (assoc-get cadr 'id attrs)))
           (when id (hash-table-set! names id #t)))
         (when (equal? 'a (car elem))
           (let ((name (assoc-get cadr 'name attrs)))
             (when name (hash-table-set! names name #t)))
           (let ((href (assoc-get cadr 'href attrs)))
             (when (and href (string-first-char? #\# href))
               (let ((anchor (substring href 1 (string-length href))))
                 (hash-table-set! hrefs anchor #t)))))))
     (call-with-input-file html-file html->sxml))
    (let loop ((hrefs (hash-table-keys hrefs)) (missing-names '()))
      (if (null? hrefs)
          (list-sort (lambda (a b) (string<? (string-downcase a)
                                             (string-downcase b)))
                     missing-names)
          (loop (cdr hrefs)
                (if (hash-table-exists? names (car hrefs))
                    missing-names
                    (cons (car hrefs) missing-names)))))))

(define (handle-file html-file)
  (disp "Missing id=\"...\" attributes in " html-file ":")
  (let ((names (missing-a-names html-file)))
    (for-each (lambda (name) (disp "  " name))
              (if (null? names) '("(none)") names))
    (newline)))

(define (main args)
  (newline)
  (for-each handle-file (cdr args)))

(cond-expand (sagittarius)
             (else (main (command-line))))
