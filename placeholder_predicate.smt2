;; Improved helper predicates for 1_smaller.c.v
;; These predicates capture the precise mathematical relationship between x and y

;; Base case: After reset, x=1 and y=0
;;(define-fun |predicate.base_case| ((x (_ BitVec 15)) (y (_ BitVec 15))) Bool
;;  (and (= x (_ bv1 15)) (= y (_ bv0 15))))

