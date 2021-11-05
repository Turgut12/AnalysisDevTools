; Changes:
; * removed: 2
; * added: 3
; * swaps: 5
; * negated predicates: 0
; * swapped branches: 1
; * calls to id fun: 10
(letrec ((lookup (lambda (key table)
                   @sensitivity:FA
                   ((letrec ((loop (lambda (x)
                                    @sensitivity:FA
                                    (if (null? x)
                                       #f
                                       (let ((pair (car x)))
                                          (if (eq? (car pair) key) pair (loop (cdr x))))))))
                      loop)
                      table)))
         (properties ())
         (get (lambda (key1 key2)
                @sensitivity:FA
                (let ((x (lookup key1 properties)))
                   (if x
                      (let ((y (lookup key2 (cdr x))))
                         (if y (cdr y) #f))
                      #f))))
         (put (lambda (key1 key2 val)
                (<change>
                   @sensitivity:FA
                   ((lambda (x) x) @sensitivity:FA))
                (let ((x (lookup key1 properties)))
                   (if x
                      (let ((y (lookup key2 (cdr x))))
                         (if y
                            (set-cdr! y val)
                            (set-cdr! x (cons (cons key2 val) (cdr x)))))
                      (set! properties (cons (list key1 (cons key2 val)) properties))))))
         (*current-gensym* 0)
         (generate-symbol (lambda ()
                            @sensitivity:FA
                            (set! *current-gensym* (+ *current-gensym* 1))
                            (string->symbol (number->string *current-gensym*))))
         (append-to-tail! (lambda (x y)
                            @sensitivity:FA
                            (if (null? x)
                               y
                               (letrec ((__do_loop (lambda (a b)
                                                     (<change>
                                                        ()
                                                        (display y))
                                                     @sensitivity:FA
                                                     (if (null? b)
                                                        (begin
                                                           (<change>
                                                              (set-cdr! a y)
                                                              ((lambda (x) x) (set-cdr! a y)))
                                                           x)
                                                        (__do_loop b (cdr b))))))
                                  (<change>
                                     (__do_loop x (cdr x))
                                     ((lambda (x) x) (__do_loop x (cdr x))))))))
         (tree-copy (lambda (x)
                      @sensitivity:FA
                      (if (not (pair? x))
                         x
                         (cons (tree-copy (car x)) (tree-copy (cdr x))))))
         (*rand* 21)
         (init (lambda (n m npats ipats)
                 (<change>
                    @sensitivity:FA
                    (let ((ipats (tree-copy ipats)))
                       ((lambda (x) x)
                          (letrec ((__do_loop (lambda (p)
                                                @sensitivity:FA
                                                (if (null? (cdr p))
                                                   (set-cdr! p ipats)
                                                   (__do_loop (cdr p))))))
                             (__do_loop ipats)))
                       ((lambda (x) x)
                          (letrec ((__do_loop (lambda (n i name a)
                                                @sensitivity:No
                                                (if (= n 0)
                                                   (begin
                                                      (set! a (cons name a))
                                                      (letrec ((__do_loop (lambda (i)
                                                                            @sensitivity:FA
                                                                            (if (zero? i) #f (begin (__do_loop (- i 1)))))))
                                                         (__do_loop i))
                                                      (put
                                                         name
                                                         'pattern
                                                         (letrec ((__do_loop (lambda (i ipats a)
                                                                               (if (zero? i)
                                                                                  a
                                                                                  (begin
                                                                                     (set! a (cons (car ipats) a))
                                                                                     (__do_loop (- i 1) (cdr ipats) a))))))
                                                            (__do_loop npats ipats ())))
                                                      ((lambda (x) x)
                                                         (letrec ((__do_loop (lambda (j)
                                                                               @sensitivity:FA
                                                                               (if (zero? j)
                                                                                  #f
                                                                                  (begin
                                                                                     generate-symbol
                                                                                     (__do_loop (- j 1))
                                                                                     (put name (generate-symbol) #f))))))
                                                            (__do_loop (- m i))))
                                                      ((lambda (x) x) (__do_loop (- n 1) (if (zero? i) m (- i 1)) (generate-symbol) a)))
                                                   a))))
                             (__do_loop n m (generate-symbol) ())))))
                 (<change>
                    (let ((ipats (tree-copy ipats)))
                       (letrec ((__do_loop (lambda (p)
                                             @sensitivity:FA
                                             (if (null? (cdr p))
                                                (set-cdr! p ipats)
                                                (__do_loop (cdr p))))))
                          (__do_loop ipats))
                       (letrec ((__do_loop (lambda (n i name a)
                                             @sensitivity:No
                                             (if (= n 0)
                                                a
                                                (begin
                                                   (set! a (cons name a))
                                                   (letrec ((__do_loop (lambda (i)
                                                                         @sensitivity:FA
                                                                         (if (zero? i)
                                                                            #f
                                                                            (begin
                                                                               (put name (generate-symbol) #f)
                                                                               (__do_loop (- i 1)))))))
                                                      (__do_loop i))
                                                   (put
                                                      name
                                                      'pattern
                                                      (letrec ((__do_loop (lambda (i ipats a)
                                                                            @sensitivity:FA
                                                                            (if (zero? i)
                                                                               a
                                                                               (begin
                                                                                  (set! a (cons (car ipats) a))
                                                                                  (__do_loop (- i 1) (cdr ipats) a))))))
                                                         (__do_loop npats ipats ())))
                                                   (letrec ((__do_loop (lambda (j)
                                                                         @sensitivity:FA
                                                                         (if (zero? j)
                                                                            #f
                                                                            (begin
                                                                               (put name (generate-symbol) #f)
                                                                               (__do_loop (- j 1)))))))
                                                      (__do_loop (- m i)))
                                                   (__do_loop (- n 1) (if (zero? i) m (- i 1)) (generate-symbol) a))))))
                          (__do_loop n m (generate-symbol) ())))
                    @sensitivity:FA)))
         (browse-random (lambda ()
                          @sensitivity:FA
                          (set! *rand* (remainder (* *rand* 17) 251))
                          *rand*))
         (randomize (lambda (l)
                      @sensitivity:FA
                      (<change>
                         (letrec ((__do_loop (lambda (a)
                                               @sensitivity:No
                                               (if (null? l)
                                                  a
                                                  (begin
                                                     (let ((n (remainder (browse-random) (length l))))
                                                        (if (zero? n)
                                                           (begin
                                                              (set! a (cons (car l) a))
                                                              (set! l (cdr l))
                                                              l)
                                                           (letrec ((__do_loop (lambda (n x)
                                                                                 @sensitivity:FA
                                                                                 (if (= n 1)
                                                                                    (begin
                                                                                       (set! a (cons (cadr x) a))
                                                                                       (set-cdr! x (cddr x))
                                                                                       x)
                                                                                    (__do_loop (- n 1) (cdr x))))))
                                                              (__do_loop n l))))
                                                     (__do_loop a))))))
                            (__do_loop ()))
                         ((lambda (x) x)
                            (letrec ((__do_loop (lambda (a)
                                                  (<change>
                                                     @sensitivity:No
                                                     (if (null? l)
                                                        a
                                                        (begin
                                                           (__do_loop a)
                                                           (let ((n (remainder (browse-random) (length l))))
                                                              (if (zero? n)
                                                                 (begin
                                                                    (set! a (cons (car l) a))
                                                                    (set! l (cdr l))
                                                                    l)
                                                                 (letrec ((__do_loop (lambda (n x)
                                                                                       (if (= n 1)
                                                                                          (begin
                                                                                             (set! a (cons (cadr x) a))
                                                                                             (set-cdr! x (cddr x))
                                                                                             x)
                                                                                          (__do_loop (- n 1) (cdr x)))
                                                                                       (display n)
                                                                                       @sensitivity:FA)))
                                                                    (__do_loop n l)))))))
                                                  (<change>
                                                     (if (null? l)
                                                        a
                                                        (begin
                                                           (let ((n (remainder (browse-random) (length l))))
                                                              (if (zero? n)
                                                                 (begin
                                                                    (set! a (cons (car l) a))
                                                                    (set! l (cdr l))
                                                                    l)
                                                                 (letrec ((__do_loop (lambda (n x)
                                                                                       @sensitivity:FA
                                                                                       (if (= n 1)
                                                                                          (begin
                                                                                             (set! a (cons (cadr x) a))
                                                                                             (set-cdr! x (cddr x))
                                                                                             x)
                                                                                          (__do_loop (- n 1) (cdr x))))))
                                                                    (__do_loop n l))))
                                                           (__do_loop a)))
                                                     @sensitivity:No))))
                               (__do_loop ()))))))
         (my-match (lambda (pat dat alist)
                     @sensitivity:No
                     (if (null? pat)
                        (null? dat)
                        (if (null? dat)
                           ()
                           (if (let ((__or_res (eq? (car pat) '?))) (if __or_res __or_res (eq? (car pat) (car dat))))
                              (my-match (cdr pat) (cdr dat) alist)
                              (if (eq? (car pat) '*)
                                 (let ((__or_res (my-match (cdr pat) dat alist)))
                                    (if __or_res
                                       __or_res
                                       (let ((__or_res (my-match (cdr pat) (cdr dat) alist)))
                                          (if __or_res
                                             __or_res
                                             (my-match pat (cdr dat) alist)))))
                                 (if (not (pair? (car pat)))
                                    (if (eq? (string-ref (symbol->string (car pat)) 0) #\?)
                                       (let ((val (assq (car pat) alist)))
                                          (if val
                                             (my-match (cons (cdr val) (cdr pat)) dat alist)
                                             (my-match (cdr pat) (cdr dat) (cons (cons (car pat) (car dat)) alist))))
                                       (if (eq? (string-ref (symbol->string (car pat)) 0) #\*)
                                          (let ((val (assq (car pat) alist)))
                                             (if val
                                                (my-match (append (cdr val) (cdr pat)) dat alist)
                                                (letrec ((__do_loop (lambda (l e d)
                                                                      @sensitivity:1A
                                                                      (if (let ((__or_res (null? e))) (if __or_res __or_res (my-match (cdr pat) d (cons (cons (car pat) l) alist))))
                                                                         (if (null? e) #f #t)
                                                                         (__do_loop
                                                                            (append-to-tail! l (cons (if (null? d) () (car d)) ()))
                                                                            (cdr e)
                                                                            (if (null? d) () (cdr d)))))))
                                                   (__do_loop () (cons () dat) dat))))
                                          #f))
                                    (if (pair? (car dat))
                                       (if (my-match (car pat) (car dat) alist)
                                          (my-match (cdr pat) (cdr dat) alist)
                                          #f)
                                       #f))))))))
         (database (randomize
                     (init
                        100
                        10
                        4
                        (__toplevel_cons
                           (__toplevel_cons
                              'a
                              (__toplevel_cons
                                 'a
                                 (__toplevel_cons
                                    'a
                                    (__toplevel_cons
                                       'b
                                       (__toplevel_cons
                                          'b
                                          (__toplevel_cons
                                             'b
                                             (__toplevel_cons
                                                'b
                                                (__toplevel_cons
                                                   'a
                                                   (__toplevel_cons
                                                      'a
                                                      (__toplevel_cons
                                                         'a
                                                         (__toplevel_cons
                                                            'a
                                                            (__toplevel_cons
                                                               'a
                                                               (__toplevel_cons
                                                                  'b
                                                                  (__toplevel_cons 'b (__toplevel_cons 'a (__toplevel_cons 'a (__toplevel_cons 'a ())))))))))))))))))
                           (__toplevel_cons
                              (__toplevel_cons
                                 'a
                                 (__toplevel_cons
                                    'a
                                    (__toplevel_cons
                                       'b
                                       (__toplevel_cons
                                          'b
                                          (__toplevel_cons
                                             'b
                                             (__toplevel_cons
                                                'b
                                                (__toplevel_cons
                                                   'a
                                                   (__toplevel_cons
                                                      'a
                                                      (__toplevel_cons
                                                         (__toplevel_cons 'a (__toplevel_cons 'a ()))
                                                         (__toplevel_cons (__toplevel_cons 'b (__toplevel_cons 'b ())) ()))))))))))
                              (__toplevel_cons
                                 (__toplevel_cons
                                    'a
                                    (__toplevel_cons
                                       'a
                                       (__toplevel_cons
                                          'a
                                          (__toplevel_cons
                                             'b
                                             (__toplevel_cons
                                                (__toplevel_cons 'b (__toplevel_cons 'a ()))
                                                (__toplevel_cons 'b (__toplevel_cons 'a (__toplevel_cons 'b (__toplevel_cons 'a ())))))))))
                                 ()))))))
         (browse (lambda (pats)
                   (<change>
                      @sensitivity:FA
                      ((lambda (x) x) @sensitivity:FA))
                   (investigate database pats)))
         (investigate (lambda (units pats)
                        @sensitivity:FA
                        (letrec ((__do_loop (lambda (units)
                                              @sensitivity:FA
                                              (if (null? units)
                                                 #f
                                                 (begin
                                                    (letrec ((__do_loop (lambda (pats)
                                                                          @sensitivity:FA
                                                                          (if (null? pats)
                                                                             #f
                                                                             (begin
                                                                                (letrec ((__do_loop (lambda (p)
                                                                                                      @sensitivity:FA
                                                                                                      (if (null? p)
                                                                                                         #f
                                                                                                         (begin
                                                                                                            (my-match (car pats) (car p) ())
                                                                                                            (__do_loop (cdr p)))))))
                                                                                   (__do_loop (get (car units) 'pattern)))
                                                                                (__do_loop (cdr pats)))))))
                                                       (__do_loop pats))
                                                    (__do_loop (cdr units)))))))
                           (__do_loop units)))))
   (<change>
      (browse
         (__toplevel_cons
            (__toplevel_cons
               '*a
               (__toplevel_cons
                  '?b
                  (__toplevel_cons
                     '*b
                     (__toplevel_cons
                        '?b
                        (__toplevel_cons
                           'a
                           (__toplevel_cons '*a (__toplevel_cons 'a (__toplevel_cons '*b (__toplevel_cons '*a ())))))))))
            (__toplevel_cons
               (__toplevel_cons
                  '*a
                  (__toplevel_cons
                     '*b
                     (__toplevel_cons
                        '*b
                        (__toplevel_cons
                           '*a
                           (__toplevel_cons (__toplevel_cons '*a ()) (__toplevel_cons (__toplevel_cons '*b ()) ()))))))
               (__toplevel_cons
                  (__toplevel_cons
                     '?
                     (__toplevel_cons
                        '?
                        (__toplevel_cons
                           '*
                           (__toplevel_cons
                              (__toplevel_cons 'b (__toplevel_cons 'a ()))
                              (__toplevel_cons '* (__toplevel_cons '? (__toplevel_cons '? ())))))))
                  ()))))
      ((lambda (x) x)
         (browse
            (__toplevel_cons
               (__toplevel_cons
                  '*a
                  (__toplevel_cons
                     '?b
                     (__toplevel_cons
                        '*b
                        (__toplevel_cons
                           '?b
                           (__toplevel_cons
                              'a
                              (__toplevel_cons '*a (__toplevel_cons 'a (__toplevel_cons '*b (__toplevel_cons '*a ())))))))))
               (__toplevel_cons
                  (__toplevel_cons
                     '*a
                     (__toplevel_cons
                        '*b
                        (__toplevel_cons
                           '*b
                           (__toplevel_cons
                              '*a
                              (__toplevel_cons (__toplevel_cons '*a ()) (__toplevel_cons (__toplevel_cons '*b ()) ()))))))
                  (__toplevel_cons
                     (__toplevel_cons
                        '?
                        (__toplevel_cons
                           '?
                           (__toplevel_cons
                              '*
                              (__toplevel_cons
                                 (__toplevel_cons 'b (__toplevel_cons 'a ()))
                                 (__toplevel_cons '* (__toplevel_cons '? (__toplevel_cons '? ())))))))
                     ()))))))
   *current-gensym*)