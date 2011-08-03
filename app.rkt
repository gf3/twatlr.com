#lang racket

(require net/url
         web-server/http
         web-server/dispatch
         web-server/servlet-env
         "vendor/twatlr/twatlr.rkt"
         (planet dyoo/string-template:1:0/string-template))

(define-values (twatlr-dispatch twatlr-url)
    (dispatch-rules
     [("") home-page]
     [("thread") redirect-thread]
     [("thread" (string-arg)) view-thread]))

(define (home-page req)
  (render home-page-tmpl))

(define (redirect-thread req)
  (let ([param (cdr (assoc 'tweet (url-query (request-uri req))))])
    (redirect-to (string-append "/thread/" (or (extract-id param) param))
                 permanently)))

(define (view-thread req t)
  (if (hash-has-key? (get-tweet t) 'error)
    (render view-thread-tmpl (hash "content" "Error!"))
    (render view-thread-tmpl (hash "content" (render-thread (get-thread t))))))

(define (not-found req)
  (response/xexpr
    `(html (head (title "Hello world!"))
           (body (p "Hey out there!")))))

(define-values (home-page-tmpl view-thread-tmpl tweet-tmpl)
  (values (make-template (file->string "./home-page.html"))
          (make-template (file->string "./view-thread.html"))
          (make-template (file->string "./_tweet.html"))))

; Render view
(define (render tmpl [data (hash)])
  (let ([output (template->string tmpl data)])
    (response/full
      200 #"Okay"
      (current-seconds) TEXT/HTML-MIME-TYPE
      (list (make-header #"Content-Length" (string->bytes/utf-8 (number->string (string-length output))))
            (make-header #"X-LOL" #"NO U"))
      (list (string->bytes/utf-8 output)))))

; Render a thread to a HTML
(define (render-thread thread)
  (string-append
    "<ol>"
    (foldr string-append
           ""
           (map (λ (t) (template->string tweet-tmpl (tweet->tmpl-hash t))) thread))
    "</ol>"))

(define (tweet->tmpl-hash t)
  (hash
    "id" (hash-ref t 'id_str)
    "username" (hash-ref (hash-ref t 'user) 'name)
    "text" (hash-ref t 'text)
    "date" (hash-ref t 'created_at)))

(define (extract-id url)
  (let ([match (regexp-match #px"\\d+$" url)])
    (if match
      (car match)
      #f)))

(define (url->request u)
  (make-request #"GET" (string->url u) empty
                (delay empty) #f "1.2.3.4" 80 "4.3.2.1"))

; (write (twatlr-dispatch
;    (url->request "http://gf3.ca/thread/1234abcd")))

(serve/servlet twatlr-dispatch
  #:extra-files-paths (list (build-path "./public"))
  #:log-file (build-path "./log/app.log")
  #:servlet-regexp #rx""
  #:servlet-path "/"
  #:launch-browser? #f)

