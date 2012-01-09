#lang racket

(require net/url
         mzlib/os
         racket/path
         web-server/http
         web-server/dispatch
         web-server/servlet-env
         "vendor/twatlr/twatlr.rkt"
         (planet dyoo/string-template:1:0/string-template))

(define app-path (path-only (find-system-path 'run-file)))

; Dispatcher
(define-values (twatlr-dispatch twatlr-url)
  (dispatch-rules
    [("") home-page]
    [("thread") redirect-thread]
    [("thread" (string-arg)) view-thread]))

; Home page responder
(define (home-page req)
  (render home-page-tmpl (hash "labelclass" "notice"
                               "labeltext"  "Enter the URL of a tweet below &darr;")))

; Redirect responder
(define (redirect-thread req)
  (match (assoc 'tweet (url-query (request-uri req)))
    [(cons k v) (redirect-to (string-append "/thread/" (or (extract-id v) v)) permanently)]
    [_ (not-found req)]))

; View thread responder
(define (view-thread req t)
  (if (extract-id t)
    (if (hash-has-key? (get-tweet t) 'error)
      (not-found req)
      (render view-thread-tmpl (hash "content" (thread->string (get-thread t)))))
    (not-found req)))

; 404 responder
(define (not-found req)
  (render home-page-tmpl (hash "labelclass" "error"
                               "labeltext"  "Not found &mdash; Try again :(")))

; Templates
(define-values (home-page-tmpl view-thread-tmpl head-tmpl tweet-tmpl tweet-error-tmpl thread-tmpl)
  (values (make-template (file->string (build-path app-path "views" "home-page.html")))
          (make-template (file->string (build-path app-path "views" "view-thread.html")))
          (make-template (file->string (build-path app-path "views" "_head.html")))
          (make-template (file->string (build-path app-path "views" "_tweet.html")))
          (make-template (file->string (build-path app-path "views" "_tweet-error.html")))
          (make-template (file->string (build-path app-path "views" "_thread.html")))))

; Render view
(define (render tmpl [data (hash)])
  (let ([output (template->string tmpl (hash-set data "head" (template->string head-tmpl (hash))))])
    (response/full
      200 #"Okay"
      (current-seconds) TEXT/HTML-MIME-TYPE
      (list (make-header #"Content-Length" (string->bytes/utf-8 (number->string (string-length output))))
            (make-header #"X-LOL" #"NO U"))
      (list (string->bytes/utf-8 output)))))

; Render 404
(define (render-404 tmpl [data (hash)])
  (let ([output (template->string tmpl data)])
    (response/full
      404 #"Not Found"
      (current-seconds) TEXT/HTML-MIME-TYPE
      (list (make-header #"Content-Length" (string->bytes/utf-8 (number->string (string-length output))))
            (make-header #"X-LOL" #"NO U"))
      (list (string->bytes/utf-8 output)))))

; Render a thread to a HTML
(define (thread->string thread)
  (template->string thread-tmpl
    (hash
      "numtweets" (number->string (length thread))
      "numusers"  (length (remove-duplicates (filter hash? (map get-user-name thread))))
      "tweets"    (foldr string-append
                    ""
                    (map tweet->string (reverse thread))))))

; Render a tweet to HTML
(define (tweet->string tweet)
  (if (hash-ref tweet 'error #f)
    (template->string tweet-error-tmpl #hash())
    (template->string tweet-tmpl (tweet->tmpl-hash tweet))))

; Convert a tweet hash (JSON) to a hash suitable for string templates
(define (tweet->tmpl-hash t)
  (hash
    "id"              (hash-ref t 'id_str)
    "username"        (hash-ref (hash-ref t 'user) 'name)
    "userscreenname"  (hash-ref (hash-ref t 'user) 'screen_name)
    "userpic"         (hash-ref (hash-ref t 'user) 'profile_image_url)
    "text"            (linkify-twitter (linkify-url (hash-ref t 'text)))
    "date"            (hash-ref t 'created_at)))

; Get the user's name for a given tweet
(define (get-user-name tweet)
  (if (hash-ref tweet 'error #f)
    #\nul
    (hash-ref (hash-ref tweet 'user) 'name)))

; Grab numeric ID from either ID or tweet URL
(define (extract-id url)
  (let ([match (regexp-match #px"\\d+$" url)])
    (if match
      (car match)
      #f)))

; Linkfiy all URLs in a string
(define (linkify-url text)
  (let ([r-http #px"^[a-z]+://"]
        [r-link #px"\\b(?:[a-z]+://)?(?<!@)[0-9a-z](?:[-\\d\\w.]*\\.)+[a-z]{2,4}(?:\\:\\d{1,6})?(?:[-\\d\\w./?=&#%+]*)\\b"])
          (regexp-replace* r-link text (λ (url)
                                        (let ([fixed-url (if (regexp-match? r-http url) url (string-append "http://" url))])
                                          (string-append "<a href=" fixed-url ">" url "</a>"))))))

; Linkify all Twitter usernames in a string
(define (linkify-twitter text)
  (regexp-replace* #px"@(\\w+)" text (λ (disp user)
                                       (string-append "<a href=http://twitter.com/" user ">" disp "</a>"))))

; URL to Request
(define (url->request u)
  (make-request #"GET" (string->url u) empty
                (delay empty) #f "1.2.3.4" 80 "4.3.2.1"))

; (write (twatlr-dispatch
;    (url->request "http://gf3.ca/thread/1234abcd")))

(with-output-to-file (build-path app-path "app.pid") (λ () (write (getpid))))
(serve/servlet twatlr-dispatch
  #:extra-files-paths (list (build-path app-path "public"))
  #:log-file (build-path app-path "log" "app.log")
  #:servlet-regexp #rx""
  #:servlet-path "/"
  #:launch-browser? #f
  #:file-not-found-responder not-found)

