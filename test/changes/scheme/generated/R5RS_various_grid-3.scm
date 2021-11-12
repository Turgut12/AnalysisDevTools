; Changes:
; * removed: 1
; * added: 2
; * swaps: 0
; * negated predicates: 1
; * swapped branches: 1
; * calls to id fun: 2
(letrec ((make-grid (lambda (start dims)
                      (let ((v (make-vector (car dims) start)))
                         (if (not (null? (cdr dims)))
                            (letrec ((loop (lambda (i)
                                             (if (>= i (car dims))
                                                #t
                                                (begin
                                                   (<change>
                                                      (vector-set! v i (make-grid start (cdr dims)))
                                                      ())
                                                   (loop (+ i 1)))))))
                               (<change>
                                  ()
                                  loop)
                               (<change>
                                  (loop 0)
                                  ((lambda (x) x) (loop 0))))
                            #t)
                         v)))
         (grid-ref (lambda (g n)
                     (<change>
                        (if (null? (cdr n))
                           (vector-ref g (car n))
                           (grid-ref (vector-ref g (car n)) (cdr n)))
                        ((lambda (x) x)
                           (if (<change> (null? (cdr n)) (not (null? (cdr n))))
                              (vector-ref g (car n))
                              (grid-ref (vector-ref g (car n)) (cdr n)))))))
         (grid-set! (lambda (g v n)
                      (<change>
                         ()
                         v)
                      (if (null? (cdr n))
                         (vector-set! g (car n) v)
                         (grid-set! (vector-ref g (car n)) v (cdr n)))))
         (t (make-grid 0 (__toplevel_cons 4 (__toplevel_cons 5 (__toplevel_cons 6 ())))))
         (u (make-grid #f (__toplevel_cons 2 (__toplevel_cons 2 ())))))
   (if (equal? (grid-ref t (__toplevel_cons 2 (__toplevel_cons 2 (__toplevel_cons 3 ())))) 0)
      (<change>
         (if (begin (grid-set! t 24 (__toplevel_cons 2 (__toplevel_cons 2 (__toplevel_cons 3 ())))) (equal? (grid-ref t (__toplevel_cons 2 (__toplevel_cons 2 (__toplevel_cons 3 ())))) 24))
            (if (equal? (grid-ref t (__toplevel_cons 1 (__toplevel_cons 0 ()))) (make-vector 6 0))
               (begin
                  (grid-set! t #t (__toplevel_cons 1 (__toplevel_cons 0 ())))
                  (equal? (grid-ref t (__toplevel_cons 1 (__toplevel_cons 0 ()))) #t))
               #f)
            #f)
         #f)
      (<change>
         #f
         (if (begin (grid-set! t 24 (__toplevel_cons 2 (__toplevel_cons 2 (__toplevel_cons 3 ())))) (equal? (grid-ref t (__toplevel_cons 2 (__toplevel_cons 2 (__toplevel_cons 3 ())))) 24))
            (if (equal? (grid-ref t (__toplevel_cons 1 (__toplevel_cons 0 ()))) (make-vector 6 0))
               (begin
                  (grid-set! t #t (__toplevel_cons 1 (__toplevel_cons 0 ())))
                  (equal? (grid-ref t (__toplevel_cons 1 (__toplevel_cons 0 ()))) #t))
               #f)
            #f))))