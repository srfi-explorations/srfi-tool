;;; Display how many times each HTML tag is used in the given SRFIs.

(import (scheme base)
        (scheme char)
        (scheme cxr)
        (scheme file)
        (scheme process-context)
        (scheme write)
        (srfi 1)
        (srfi 69)
        (srfi 95))

(cond-expand (chibi  (import (chibi io) (chibi string)))
             (gauche (import (srfi 13) (gauche base))))

(import (chibi html-parser))

(define make-set make-hash-table)
(define set-elems hash-table-keys)
(define (add-to-set elem set) (hash-table-set! set elem #t) set)
(define (symbol<? a b) (string<? (symbol->string a) (symbol->string b)))

(define (hash-table-increment! table key)
  (hash-table-update!/default table key (lambda (x) (+ x 1)) 0))

(define (symbol-prefix? prefix sym)
  (string-prefix? prefix (symbol->string sym)))

(define (displayln . xs)
  (for-each display xs)
  (newline))

(define (tag-body elem)
  (cond ((not (pair? (cdr elem))) '())
        ((and (pair? (cadr elem)) (eqv? '@ (caadr elem)))
         (cddr elem))
        (else (cdr elem))))

(define (tag-names-fold elem kons knil)
  (let do-elem ((elem elem) (acc knil))
    (if (not (pair? elem)) acc
        (let do-list ((elems (tag-body elem)) (acc (kons (car elem) acc)))
          (if (null? elems) acc
              (do-list (cdr elems) (do-elem (car elems) acc)))))))

(define (count-html-file-tags! html-file counts)
  (let* ((html (call-with-input-file html-file port->string))
         (sxml (call-with-input-string html html->sxml)))
    (tag-names-fold sxml
                    (lambda (tag counts)
                      (unless (symbol-prefix? "*" tag)
                        (hash-table-increment! counts tag))
                      counts)
                    counts)))

(define (main html-files)
  (let ((counts (make-hash-table)))
    (for-each (lambda (html-file)
                (count-html-file-tags! html-file counts))
              html-files)
    (for-each (lambda (tag-name)
                (let ((count (hash-table-ref counts tag-name)))
                  (displayln (list tag-name count))))
              (sort (hash-table-keys counts)
                    (lambda (tag-a tag-b)
                      (> (hash-table-ref counts tag-a)
                         (hash-table-ref counts tag-b)))))))

(main (cdr (command-line)))
