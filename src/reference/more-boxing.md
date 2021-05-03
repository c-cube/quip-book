# More on boxing

If two clauses `C` and `D` are known to be equivalent, but are not syntactically the same,
one can prove `(cl (- (box C)) (+ (box D)))` (and conversely) as follows.

Let's assume `C` is `(cl (+ a) (+ b))`, `D` is `(cl (+ a2) (+ b2))`,
and we have some clauses `PA` and `PB` proving `(= a a2)` and `(= b b2)`:

```
(steps
 ((hyp_bc (box C)))
 (
  ; first use box-assume
  (stepc s1 (cl (- (box C)) (+ a) (+ b)) (box-assume C))

  ; discharge the box locally using the assumption
  (stepc s2 (cl (+ a) (+ b))
    (hres (init (ref s1)) (r1 (ref hyp_bc))))

  ; prove D
  (stepc s3 (cl (+ a2) (+ b2))
    (hres
      (init (res s2))
      (p1 (ref PA)) ; a=a2
      (p1 (ref PB)) ; b=b2
      ))

  ; box D
  (stepc s4 (cl (+ (box D)))
    (box-proof (ref s3)))))
```

Because we add the negation of the assumptions,
the result of this sub-proof
is thus `(cl (- (box C)) (+ (box D)))`.

We used the assumption mechanism to get rid of `(- (box C))` locally
to avoiding boxing it along with the other literals
when we apply `box-proof`.
