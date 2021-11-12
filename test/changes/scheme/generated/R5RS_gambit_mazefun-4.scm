; Changes:
; * removed: 0
; * added: 1
; * swaps: 0
; * negated predicates: 3
; * swapped branches: 0
; * calls to id fun: 6
(letrec ((foldr (lambda (f base lst)
                  (letrec ((foldr-aux (lambda (lst)
                                        (if (null? lst)
                                           base
                                           (f (car lst) (foldr-aux (cdr lst)))))))
                     (foldr-aux lst))))
         (foldl (lambda (f base lst)
                  (letrec ((foldl-aux (lambda (base lst)
                                        (if (null? lst)
                                           base
                                           (foldl-aux (f base (car lst)) (cdr lst))))))
                     (foldl-aux base lst))))
         (for (lambda (lo hi f)
                (letrec ((for-aux (lambda (lo)
                                    (if (< lo hi)
                                       (cons (f lo) (for-aux (+ lo 1)))
                                       ()))))
                   (for-aux lo))))
         (concat (lambda (lists)
                   (foldr append () lists)))
         (list-read (lambda (lst i)
                      (<change>
                         ()
                         cdr)
                      (if (= i 0)
                         (car lst)
                         (list-read (cdr lst) (- i 1)))))
         (list-write (lambda (lst i val)
                       (if (= i 0)
                          (cons val (cdr lst))
                          (cons (car lst) (list-write (cdr lst) (- i 1) val)))))
         (list-remove-pos (lambda (lst i)
                            (<change>
                               (if (= i 0)
                                  (cdr lst)
                                  (cons (car lst) (list-remove-pos (cdr lst) (- i 1))))
                               ((lambda (x) x) (if (= i 0) (cdr lst) (cons (car lst) (list-remove-pos (cdr lst) (- i 1))))))))
         (duplicates? (lambda (lst)
                        (if (<change> (null? lst) (not (null? lst)))
                           #f
                           (let ((__or_res (member (car lst) (cdr lst))))
                              (if __or_res __or_res (duplicates? (cdr lst)))))))
         (make-matrix (lambda (n m init)
                        (for 0 n (lambda (i) (for 0 m (lambda (j) (init i j)))))))
         (matrix-read (lambda (mat i j)
                        (list-read (list-read mat i) j)))
         (matrix-write (lambda (mat i j val)
                         (list-write mat i (list-write (list-read mat i) j val))))
         (matrix-size (lambda (mat)
                        (cons (length mat) (length (car mat)))))
         (matrix-map (lambda (f mat)
                       (map (lambda (lst) (map f lst)) mat)))
         (initial-random 0)
         (next-random (lambda (current-random)
                        (<change>
                           (remainder (+ (* current-random 3581) 12751) 131072)
                           ((lambda (x) x) (remainder (+ (* current-random 3581) 12751) 131072)))))
         (shuffle (lambda (lst)
                    (shuffle-aux lst initial-random)))
         (shuffle-aux (lambda (lst current-random)
                        (if (<change> (null? lst) (not (null? lst)))
                           ()
                           (let ((new-random (next-random current-random)))
                              (<change>
                                 (let ((i (modulo new-random (length lst))))
                                    (cons (list-read lst i) (shuffle-aux (list-remove-pos lst i) new-random)))
                                 ((lambda (x) x)
                                    (let ((i (modulo new-random (length lst))))
                                       (cons (list-read lst i) (shuffle-aux (list-remove-pos lst i) new-random)))))))))
         (make-maze (lambda (n m)
                      (if (not (if (<change> (odd? n) (not (odd? n))) (odd? m) #f))
                         'error
                         (let ((cave (make-matrix
                                       n
                                       m
                                       (lambda (i j)
                                          (<change>
                                             (if (if (even? i) (even? j) #f) (cons i j) #f)
                                             ((lambda (x) x) (if (if (even? i) (even? j) #f) (cons i j) #f))))))
                               (possible-holes (concat
                                                 (for
                                                    0
                                                    n
                                                    (lambda (i)
                                                       (concat (for 0 m (lambda (j) (if (equal? (even? i) (even? j)) () (list (cons i j)))))))))))
                            (cave-to-maze (pierce-randomly (shuffle possible-holes) cave))))))
         (cave-to-maze (lambda (cave)
                         (<change>
                            (matrix-map (lambda (x) (if x '_ '*)) cave)
                            ((lambda (x) x) (matrix-map (lambda (x) (if x '_ '*)) cave)))))
         (pierce (lambda (pos cave)
                   (let ((i (car pos))
                         (j (cdr pos)))
                      (matrix-write cave i j pos))))
         (pierce-randomly (lambda (possible-holes cave)
                            (if (null? possible-holes)
                               cave
                               (let ((hole (car possible-holes)))
                                  (pierce-randomly (cdr possible-holes) (try-to-pierce hole cave))))))
         (try-to-pierce (lambda (pos cave)
                          (let ((i (car pos))
                                (j (cdr pos)))
                             (let ((ncs (neighboring-cavities pos cave)))
                                (if (duplicates? (map (lambda (nc) (matrix-read cave (car nc) (cdr nc))) ncs))
                                   cave
                                   (pierce pos (foldl (lambda (c nc) (change-cavity c nc pos)) cave ncs)))))))
         (change-cavity (lambda (cave pos new-cavity-id)
                          (let ((i (car pos))
                                (j (cdr pos)))
                             (change-cavity-aux cave pos new-cavity-id (matrix-read cave i j)))))
         (change-cavity-aux (lambda (cave pos new-cavity-id old-cavity-id)
                              (let ((i (car pos))
                                    (j (cdr pos)))
                                 (let ((cavity-id (matrix-read cave i j)))
                                    (if (equal? cavity-id old-cavity-id)
                                       (foldl
                                          (lambda (c nc)
                                             (change-cavity-aux c nc new-cavity-id old-cavity-id))
                                          (matrix-write cave i j new-cavity-id)
                                          (neighboring-cavities pos cave))
                                       cave)))))
         (neighboring-cavities (lambda (pos cave)
                                 (let ((size (matrix-size cave)))
                                    (let ((n (car size))
                                          (m (cdr size)))
                                       (let ((i (car pos))
                                             (j (cdr pos)))
                                          (append
                                             (if (if (> i 0) (matrix-read cave (- i 1) j) #f)
                                                (list (cons (- i 1) j))
                                                ())
                                             (append
                                                (if (if (< i (- n 1)) (matrix-read cave (+ i 1) j) #f)
                                                   (list (cons (+ i 1) j))
                                                   ())
                                                (append
                                                   (if (if (> j 0) (matrix-read cave i (- j 1)) #f)
                                                      (list (cons i (- j 1)))
                                                      ())
                                                   (if (if (< j (- m 1)) (matrix-read cave i (+ j 1)) #f)
                                                      (list (cons i (+ j 1)))
                                                      ())))))))))
         (expected-result (__toplevel_cons
                            (__toplevel_cons
                               '_
                               (__toplevel_cons
                                  '*
                                  (__toplevel_cons
                                     '_
                                     (__toplevel_cons
                                        '_
                                        (__toplevel_cons
                                           '_
                                           (__toplevel_cons
                                              '_
                                              (__toplevel_cons
                                                 '_
                                                 (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ ())))))))))))
                            (__toplevel_cons
                               (__toplevel_cons
                                  '_
                                  (__toplevel_cons
                                     '*
                                     (__toplevel_cons
                                        '*
                                        (__toplevel_cons
                                           '*
                                           (__toplevel_cons
                                              '*
                                              (__toplevel_cons
                                                 '*
                                                 (__toplevel_cons
                                                    '*
                                                    (__toplevel_cons '* (__toplevel_cons '_ (__toplevel_cons '* (__toplevel_cons '* ())))))))))))
                               (__toplevel_cons
                                  (__toplevel_cons
                                     '_
                                     (__toplevel_cons
                                        '_
                                        (__toplevel_cons
                                           '_
                                           (__toplevel_cons
                                              '*
                                              (__toplevel_cons
                                                 '_
                                                 (__toplevel_cons
                                                    '_
                                                    (__toplevel_cons
                                                       '_
                                                       (__toplevel_cons '* (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ ())))))))))))
                                  (__toplevel_cons
                                     (__toplevel_cons
                                        '_
                                        (__toplevel_cons
                                           '*
                                           (__toplevel_cons
                                              '_
                                              (__toplevel_cons
                                                 '*
                                                 (__toplevel_cons
                                                    '_
                                                    (__toplevel_cons
                                                       '*
                                                       (__toplevel_cons
                                                          '_
                                                          (__toplevel_cons '* (__toplevel_cons '_ (__toplevel_cons '* (__toplevel_cons '_ ())))))))))))
                                     (__toplevel_cons
                                        (__toplevel_cons
                                           '_
                                           (__toplevel_cons
                                              '*
                                              (__toplevel_cons
                                                 '_
                                                 (__toplevel_cons
                                                    '_
                                                    (__toplevel_cons
                                                       '_
                                                       (__toplevel_cons
                                                          '*
                                                          (__toplevel_cons
                                                             '_
                                                             (__toplevel_cons '* (__toplevel_cons '_ (__toplevel_cons '* (__toplevel_cons '_ ())))))))))))
                                        (__toplevel_cons
                                           (__toplevel_cons
                                              '*
                                              (__toplevel_cons
                                                 '*
                                                 (__toplevel_cons
                                                    '_
                                                    (__toplevel_cons
                                                       '*
                                                       (__toplevel_cons
                                                          '*
                                                          (__toplevel_cons
                                                             '*
                                                             (__toplevel_cons
                                                                '*
                                                                (__toplevel_cons '* (__toplevel_cons '_ (__toplevel_cons '* (__toplevel_cons '_ ())))))))))))
                                           (__toplevel_cons
                                              (__toplevel_cons
                                                 '_
                                                 (__toplevel_cons
                                                    '*
                                                    (__toplevel_cons
                                                       '_
                                                       (__toplevel_cons
                                                          '_
                                                          (__toplevel_cons
                                                             '_
                                                             (__toplevel_cons
                                                                '_
                                                                (__toplevel_cons
                                                                   '_
                                                                   (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '* (__toplevel_cons '_ ())))))))))))
                                              (__toplevel_cons
                                                 (__toplevel_cons
                                                    '_
                                                    (__toplevel_cons
                                                       '*
                                                       (__toplevel_cons
                                                          '_
                                                          (__toplevel_cons
                                                             '*
                                                             (__toplevel_cons
                                                                '_
                                                                (__toplevel_cons
                                                                   '*
                                                                   (__toplevel_cons
                                                                      '*
                                                                      (__toplevel_cons '* (__toplevel_cons '* (__toplevel_cons '* (__toplevel_cons '* ())))))))))))
                                                 (__toplevel_cons
                                                    (__toplevel_cons
                                                       '_
                                                       (__toplevel_cons
                                                          '_
                                                          (__toplevel_cons
                                                             '_
                                                             (__toplevel_cons
                                                                '*
                                                                (__toplevel_cons
                                                                   '_
                                                                   (__toplevel_cons
                                                                      '_
                                                                      (__toplevel_cons
                                                                         '_
                                                                         (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ ())))))))))))
                                                    (__toplevel_cons
                                                       (__toplevel_cons
                                                          '_
                                                          (__toplevel_cons
                                                             '*
                                                             (__toplevel_cons
                                                                '*
                                                                (__toplevel_cons
                                                                   '*
                                                                   (__toplevel_cons
                                                                      '*
                                                                      (__toplevel_cons
                                                                         '*
                                                                         (__toplevel_cons
                                                                            '*
                                                                            (__toplevel_cons '* (__toplevel_cons '_ (__toplevel_cons '* (__toplevel_cons '* ())))))))))))
                                                       (__toplevel_cons
                                                          (__toplevel_cons
                                                             '_
                                                             (__toplevel_cons
                                                                '*
                                                                (__toplevel_cons
                                                                   '_
                                                                   (__toplevel_cons
                                                                      '_
                                                                      (__toplevel_cons
                                                                         '_
                                                                         (__toplevel_cons
                                                                            '_
                                                                            (__toplevel_cons
                                                                               '_
                                                                               (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ (__toplevel_cons '_ ())))))))))))
                                                          ())))))))))))))
   (<change>
      (equal? (make-maze 11 11) expected-result)
      ((lambda (x) x) (equal? (make-maze 11 11) expected-result))))