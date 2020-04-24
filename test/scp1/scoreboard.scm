(define result '())
(define display (lambda (i) (set! result (cons i result))))
(define newline (lambda () (set! result (cons 'newline result))))

(define (create-counter)
  (let ((value 0))

    (define (reset)
      (set! value 0)
      'ok)

    (define (next)
      (set! value (+ 1 value))
      'ok)

    (define (increase x)
      (set! value (+ value x)))

    (define (dispatch msg)
      (cond ((eq? msg 'reset) reset)
            ((eq? msg 'next) next)
            ((eq? msg 'read) value)
            ((eq? msg 'increase) increase)
            (else (error "wrong message: " msg))))
    dispatch))


(define (make-scorebord)
  (let ((c-home (create-counter))
        (c-visit (create-counter)))

    (define (reset)
      ((c-home 'reset))
      ((c-visit 'reset))
      'ok)

    (define (read)
      (let ((c1 (c-home 'read))
            (c2 (c-visit 'read)))
        (display c1)
        (display "-")
        (display c2)
        (newline)
        'ok))

    (define (score team n)
      (cond ((not (or (= n 1) (= n 2) (= n 3)))
             (newline)
             (display "De score kan slechts 1, 2 of 3 zijn!")
             (newline)
             'ok)
            ((eq? team 'home)
             ((c-home 'increase) n)
             'ok)
            ((eq? team 'visit)
             ((c-visit 'increase) n)
             'ok)
            (else (error "wrong team: " team))))

    (define (dispatch msg)
      (cond ((eq? msg 'reset) reset)
            ((eq? msg 'read) read)
            ((eq? msg 'score) score)
            (else (error "wrong message: " msg))))
    dispatch))

(define bord (make-scorebord))
((bord 'read))
((bord 'score) 'home 2)
((bord 'read))
((bord 'score) 'visit 5)
((bord 'read))
((bord 'reset))
((bord 'read))
(equal? result '(newline 0 "-" 0 newline 0 "-" 2 newline "De score kan slechts 1, 2 of 3 zijn!" newline newline 0 "-" 2 newline 0 "-" 0))