; Changes:
; * removed: 1
; * added: 2
; * swaps: 0
; * negated predicates: 0
; * swapped branches: 2
; * calls to id fun: 5
(letrec ((main (lambda args
                 (let ((n (if (null? args) 0 (car args))))
                    (setup-boyer)
                    ((lambda (rewrites)
                       (if (number? rewrites)
                          (if (eq? n 0)
                             (= rewrites 95024)
                             (if (eq? n 1)
                                (= rewrites 591777)
                                (if (eq? n 2)
                                   (= rewrites 1813975)
                                   (if (eq? n 3)
                                      (= rewrites 5375678)
                                      (if (eq? n 4)
                                         (= rewrites 16445406)
                                         (if (eq? n 5) (= rewrites 51507739) #t))))))
                          #f))
                       (test-boyer
                          (__toplevel_cons
                             (__toplevel_cons
                                'x
                                (__toplevel_cons
                                   'f
                                   (__toplevel_cons
                                      (__toplevel_cons
                                         'plus
                                         (__toplevel_cons
                                            (__toplevel_cons 'plus (__toplevel_cons 'a (__toplevel_cons 'b ())))
                                            (__toplevel_cons
                                               (__toplevel_cons 'plus (__toplevel_cons 'c (__toplevel_cons (__toplevel_cons 'zero ()) ())))
                                               ())))
                                      ())))
                             (__toplevel_cons
                                (__toplevel_cons
                                   'y
                                   (__toplevel_cons
                                      'f
                                      (__toplevel_cons
                                         (__toplevel_cons
                                            'times
                                            (__toplevel_cons
                                               (__toplevel_cons 'times (__toplevel_cons 'a (__toplevel_cons 'b ())))
                                               (__toplevel_cons (__toplevel_cons 'plus (__toplevel_cons 'c (__toplevel_cons 'd ()))) ())))
                                         ())))
                                (__toplevel_cons
                                   (__toplevel_cons
                                      'z
                                      (__toplevel_cons
                                         'f
                                         (__toplevel_cons
                                            (__toplevel_cons
                                               'reverse
                                               (__toplevel_cons
                                                  (__toplevel_cons
                                                     'append
                                                     (__toplevel_cons
                                                        (__toplevel_cons 'append (__toplevel_cons 'a (__toplevel_cons 'b ())))
                                                        (__toplevel_cons (__toplevel_cons 'nil ()) ())))
                                                  ()))
                                            ())))
                                   (__toplevel_cons
                                      (__toplevel_cons
                                         'u
                                         (__toplevel_cons
                                            'equal
                                            (__toplevel_cons
                                               (__toplevel_cons 'plus (__toplevel_cons 'a (__toplevel_cons 'b ())))
                                               (__toplevel_cons (__toplevel_cons 'difference (__toplevel_cons 'x (__toplevel_cons 'y ()))) ()))))
                                      (__toplevel_cons
                                         (__toplevel_cons
                                            'w
                                            (__toplevel_cons
                                               'lessp
                                               (__toplevel_cons
                                                  (__toplevel_cons 'remainder (__toplevel_cons 'a (__toplevel_cons 'b ())))
                                                  (__toplevel_cons
                                                     (__toplevel_cons
                                                        'member
                                                        (__toplevel_cons 'a (__toplevel_cons (__toplevel_cons 'length (__toplevel_cons 'b ())) ())))
                                                     ()))))
                                         ())))))
                          (__toplevel_cons
                             'implies
                             (__toplevel_cons
                                (__toplevel_cons
                                   'and
                                   (__toplevel_cons
                                      (__toplevel_cons 'implies (__toplevel_cons 'x (__toplevel_cons 'y ())))
                                      (__toplevel_cons
                                         (__toplevel_cons
                                            'and
                                            (__toplevel_cons
                                               (__toplevel_cons 'implies (__toplevel_cons 'y (__toplevel_cons 'z ())))
                                               (__toplevel_cons
                                                  (__toplevel_cons
                                                     'and
                                                     (__toplevel_cons
                                                        (__toplevel_cons 'implies (__toplevel_cons 'z (__toplevel_cons 'u ())))
                                                        (__toplevel_cons (__toplevel_cons 'implies (__toplevel_cons 'u (__toplevel_cons 'w ()))) ())))
                                                  ())))
                                         ())))
                                (__toplevel_cons (__toplevel_cons 'implies (__toplevel_cons 'x (__toplevel_cons 'w ()))) ())))
                          4)))))
         (setup-boyer (lambda ()
                        #t))
         (test-boyer (lambda ()
                       #t)))
   (let ()
      (letrec ((setup (lambda ()
                        (add-lemma-lst '())))

               (add-lemma-lst (lambda (lst)
                                (<change>
                                   (if (null? lst)
                                      #t
                                      (begin
                                         (add-lemma (car lst))
                                         (add-lemma-lst (cdr lst))))
                                   ((lambda (x) x) (if (null? lst) #t (begin (add-lemma (car lst)) (add-lemma-lst (cdr lst))))))))
               (add-lemma (lambda (term)
                            (if (if (pair? term) (if (eq? (car term) 'equal) (pair? (cadr term)) #f) #f)
                               (put (car (cadr term)) 'lemmas (cons (translate-term term) (get (car (cadr term)) 'lemmas)))
                               (error "ADD-LEMMA did not like term "))))
               (translate-term (lambda (term)
                                 (if (not (pair? term))
                                    term
                                    (cons (symbol->symbol-record (car term)) (translate-args (cdr term))))))
               (translate-args (lambda (lst)
                                 (if (null? lst)
                                    ()
                                    (cons (translate-term (car lst)) (translate-args (cdr lst))))))
               (untranslate-term (lambda (term)
                                   (if (not (pair? term))
                                      term
                                      (cons (get-name (car term)) (map untranslate-term (cdr term))))))
               (put (lambda (sym property value)
                      (put-lemmas! (symbol->symbol-record sym) value)))
               (get (lambda (sym property)
                      (get-lemmas (symbol->symbol-record sym))))
               (symbol->symbol-record (lambda (sym)
                                        (let ((x (assq sym *symbol-records-alist*)))
                                           (if x
                                              (cdr x)
                                              (let ((r (make-symbol-record sym)))
                                                 (set! *symbol-records-alist* (cons (cons sym r) *symbol-records-alist*))
                                                 r)))))
               (*symbol-records-alist* ())
               (make-symbol-record (lambda (sym)
                                     (<change>
                                        (cons sym ())
                                        ((lambda (x) x) (cons sym ())))))
               (put-lemmas! (lambda (symbol-record lemmas)
                              (set-cdr! symbol-record lemmas)))
               (get-lemmas (lambda (symbol-record)
                             (cdr symbol-record)))
               (get-name (lambda (symbol-record)
                           (car symbol-record)))
               (symbol-record-equal? (lambda (r1 r2)
                                       (eq? r1 r2)))
               (test (lambda (alist term n)
                       (let ((term (apply-subst
                                     (translate-alist alist)
                                     (translate-term
                                        (letrec ((__do_loop (lambda (term n)
                                                              (if (zero? n)
                                                                 term
                                                                 (__do_loop (list 'or term (__toplevel_cons 'f ())) (- n 1))))))
                                           (__do_loop term n))))))
                          (<change>
                             (tautp term)
                             ((lambda (x) x) (tautp term))))))
               (translate-alist (lambda (alist)
                                  (if (null? alist)
                                     ()
                                     (cons (cons (caar alist) (translate-term (cdar alist))) (translate-alist (cdr alist))))))
               (apply-subst (lambda (alist term)
                              (<change>
                                 (if (not (pair? term))
                                    (let ((temp-temp (assq term alist)))
                                       (if temp-temp (cdr temp-temp) term))
                                    (cons (car term) (apply-subst-lst alist (cdr term))))
                                 ((lambda (x) x)
                                    (if (not (pair? term))
                                       (let ((temp-temp (assq term alist)))
                                          (if temp-temp (cdr temp-temp) term))
                                       (cons (car term) (apply-subst-lst alist (cdr term))))))))
               (apply-subst-lst (lambda (alist lst)
                                  (if (null? lst)
                                     ()
                                     (cons (apply-subst alist (car lst)) (apply-subst-lst alist (cdr lst))))))
               (tautp (lambda (x)
                        (<change>
                           ()
                           rewrite)
                        (tautologyp (rewrite x) () ())))
               (tautologyp (lambda (x true-lst false-lst)
                             (if (truep x true-lst)
                                #t
                                (if (falsep x false-lst)
                                   #f
                                   (if (not (pair? x))
                                      #f
                                      (if (eq? (car x) if-constructor)
                                         (if (truep (cadr x) true-lst)
                                            (tautologyp (caddr x) true-lst false-lst)
                                            (if (falsep (cadr x) false-lst)
                                               (tautologyp (cadddr x) true-lst false-lst)
                                               (if (tautologyp (caddr x) (cons (cadr x) true-lst) false-lst)
                                                  (tautologyp (cadddr x) true-lst (cons (cadr x) false-lst))
                                                  #f)))
                                         #f))))))
               (if-constructor '*)
               (rewrite-count 0)
               (rewrite (lambda (term)
                          (set! rewrite-count (+ rewrite-count 1))
                          (if (not (pair? term))
                             term
                             (rewrite-with-lemmas (cons (car term) (rewrite-args (cdr term))) (get-lemmas (car term))))))
               (rewrite-args (lambda (lst)
                               (if (null? lst)
                                  ()
                                  (cons (rewrite (car lst)) (rewrite-args (cdr lst))))))
               (rewrite-with-lemmas (lambda (term lst)
                                      (if (null? lst)
                                         term
                                         (if (one-way-unify term (cadr (car lst)))
                                            (rewrite (apply-subst unify-subst (caddr (car lst))))
                                            (rewrite-with-lemmas term (cdr lst))))))
               (unify-subst '*)
               (one-way-unify (lambda (term1 term2)
                                (<change>
                                   (begin
                                      (set! unify-subst ())
                                      (one-way-unify1 term1 term2))
                                   ((lambda (x) x) (begin (set! unify-subst ()) (one-way-unify1 term1 term2))))))
               (one-way-unify1 (lambda (term1 term2)
                                 (if (not (pair? term2))
                                    (let ((temp-temp (assq term2 unify-subst)))
                                       (if temp-temp
                                          (<change>
                                             (term-equal? term1 (cdr temp-temp))
                                             (if (number? term2)
                                                (equal? term1 term2)
                                                (begin
                                                   (set! unify-subst (cons (cons term2 term1) unify-subst))
                                                   #t)))
                                          (<change>
                                             (if (number? term2)
                                                (equal? term1 term2)
                                                (begin
                                                   (set! unify-subst (cons (cons term2 term1) unify-subst))
                                                   #t))
                                             (term-equal? term1 (cdr temp-temp)))))
                                    (if (not (pair? term1))
                                       #f
                                       (if (eq? (car term1) (car term2))
                                          (one-way-unify1-lst (cdr term1) (cdr term2))
                                          #f)))))
               (one-way-unify1-lst (lambda (lst1 lst2)
                                     (if (null? lst1)
                                        (null? lst2)
                                        (if (null? lst2)
                                           (<change>
                                              #f
                                              (if (one-way-unify1 (car lst1) (car lst2))
                                                 (one-way-unify1-lst (cdr lst1) (cdr lst2))
                                                 #f))
                                           (<change>
                                              (if (one-way-unify1 (car lst1) (car lst2))
                                                 (one-way-unify1-lst (cdr lst1) (cdr lst2))
                                                 #f)
                                              #f)))))
               (falsep (lambda (x lst)
                         (let ((__or_res (term-equal? x false-term)))
                            (if __or_res __or_res (term-member? x lst)))))
               (truep (lambda (x lst)
                        (let ((__or_res (term-equal? x true-term)))
                           (if __or_res __or_res (term-member? x lst)))))
               (false-term '*)
               (true-term '*)
               (trans-of-implies (lambda (n)
                                   (translate-term (list 'implies (trans-of-implies1 n) (list 'implies 0 n)))))
               (trans-of-implies1 (lambda (n)
                                    (if (equal? n 1)
                                       (list 'implies 0 1)
                                       (list 'and (list 'implies (- n 1) n) (trans-of-implies1 (- n 1))))))
               (term-equal? (lambda (x y)
                              (if (pair? x)
                                 (if (pair? y)
                                    (if (symbol-record-equal? (car x) (car y))
                                       (term-args-equal? (cdr x) (cdr y))
                                       #f)
                                    #f)
                                 (equal? x y))))
               (term-args-equal? (lambda (lst1 lst2)
                                   (if (null? lst1)
                                      (null? lst2)
                                      (if (null? lst2)
                                         #f
                                         (if (term-equal? (car lst1) (car lst2))
                                            (term-args-equal? (cdr lst1) (cdr lst2))
                                            #f)))))
               (term-member? (lambda (x lst)
                               (if (null? lst)
                                  #f
                                  (if (term-equal? x (car lst))
                                     #t
                                     (term-member? x (cdr lst)))))))
         (<change>
            (set! setup-boyer (lambda ()
                              (set! *symbol-records-alist* ())
                              (set! if-constructor (symbol->symbol-record 'if))
                              (set! false-term (translate-term (__toplevel_cons 'f ())))
                              (set! true-term (translate-term (__toplevel_cons 't ())))
                              (setup)))
            ())
         (<change>
            ()
            n)
         (set! test-boyer (lambda (alist term n)
                          (set! rewrite-count 0)
                          (let ((answer (test alist term n)))
                             (if answer rewrite-count #f))))))
   (main 4))