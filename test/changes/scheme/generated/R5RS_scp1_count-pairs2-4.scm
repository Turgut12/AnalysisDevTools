; Changes:
; * removed: 0
; * added: 0
; * swaps: 0
; * negated predicates: 1
; * swapped branches: 0
; * calls to id fun: 4
(letrec ((count-pairs (lambda (lst)
                        (let ((path ()))
                           (letrec ((count (lambda (current)
                                             (if (<change> (null? current) (not (null? current)))
                                                0
                                                (if (not (pair? current))
                                                   0
                                                   (if (memq current path)
                                                      0
                                                      (begin
                                                         (set! path (cons current path))
                                                         (<change>
                                                            (+ 1 (count (car current)) (count (cdr current)))
                                                            ((lambda (x) x) (+ 1 (count (car current)) (count (cdr current))))))))))))
                              (count lst)))))
         (ret3 (cons 'a (cons 'b (cons 'c ()))))
         (ret4 (let ((last (cons 'c ())))
                 (cons last (cons 'b last))))
         (ret7 (let* ((last (cons 'c ()))
                     (middle (cons last last)))
                 (<change>
                    (cons middle middle)
                    ((lambda (x) x) (cons middle middle)))))
         (retno (let* ((last (cons 'c ()))
                      (lst (cons 'a (cons 'b last))))
                  (set-cdr! last lst)
                  (<change>
                     lst
                     ((lambda (x) x) lst)))))
   (<change>
      (= 3 (count-pairs ret3) (count-pairs ret4) (count-pairs ret7) (count-pairs retno))
      ((lambda (x) x) (= 3 (count-pairs ret3) (count-pairs ret4) (count-pairs ret7) (count-pairs retno)))))