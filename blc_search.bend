# This program implements a Binary Lambda Calculus (BLC) interpreter.
# It also searches for a BLC term equivalent to the 'Not' function.
# It runs at ~1000 MIPS on GPU and ~2000 MIPS on CPU.

type Pair  = (New fst snd)
type Bits  = E | (O Bits) | (I Bits)
type Maybe = None | (Some value)
type Term  = (Lam bod) | (App fun arg) | (Var idx)

(String/concat String/Nil         ys) = ys
(String/concat (String/Cons x xs) ys) = (String/Cons x (String/concat xs ys))

(Join List/Nil)         = String/Nil
(Join (List/Cons x xs)) = (String/concat x (Join xs))

(Case (Maybe/Some x) some none) = (some x)
(Case Maybe/None     some none) = none

(Bits/concat (Bits/O xs) ys) = (Bits/O (Bits/concat xs ys))
(Bits/concat (Bits/I xs) ys) = (Bits/I (Bits/concat xs ys))
(Bits/concat Bits/E      ys) = ys

(Bits/reverse bs) = (Bits/reverse/go bs Bits/E)

(Bits/reverse/go Bits/E      acc) = acc
(Bits/reverse/go (Bits/O bs) acc) = (Bits/reverse/go bs (Bits/O acc))
(Bits/reverse/go (Bits/I bs) acc) = (Bits/reverse/go bs (Bits/I acc))

(Bits/tail (Bits/O bs)) = bs
(Bits/tail (Bits/I bs)) = bs
(Bits/tail Bits/E)      = Bits/E

(Maybe/or (Maybe/Some a) b) = (Maybe/Some a)
(Maybe/or Maybe/None     b) = b

(Maybe/bind (Maybe/Some a) b) = (b a)
(Maybe/bind Maybe/None     b) = Maybe/None

(List/tail (List/Cons x xs)) = xs
(List/tail List/Nil)         = List/Nil

(Pair/get (Pair/New a b) fn) = (fn a b)

(Pair/fst (Pair/New a b)) = a
(Pair/snd (Pair/New a b)) = b

(Parse (Bits/O (Bits/O bs))) =
  (Maybe/bind (Parse bs) λp(Pair/get p λbs λbod
  (Maybe/Some (Pair/New bs (Term/Lam bod)))))
(Parse (Bits/O (Bits/I bs))) =
  (Maybe/bind (Parse bs) λp(Pair/get p λbs λfun
  (Maybe/bind (Parse bs) λp(Pair/get p λbs λarg
  (Maybe/Some (Pair/New bs (Term/App fun arg)))))))
(Parse (Bits/O Bits/E))  = Maybe/None
(Parse (Bits/I bs)) = (ParseVar (Bits/I bs) 0)
(Parse Bits/E)      = Maybe/None

(ParseVar (Bits/I bs) n) = (ParseVar bs (+ n 1))
(ParseVar (Bits/O bs) n) = (Maybe/Some (Pair/New bs (Term/Var (- n 1))))
(ParseVar Bits/E      n) = Maybe/None

(DoParse bs) = (DoParse/go (Parse bs))

(DoParse/go (Maybe/Some p)) = (Pair/get p λ_ λtm tm)
(DoParse/go Maybe/None)     = (Term/Var 0)

(View (Term/Lam bod))     = (String/concat "λ" (View bod))
(View (Term/App fun arg)) = (String/concat "(" (String/concat (View fun) (String/concat " " (String/concat (View arg) ")"))))
(View (Term/Var idx))     = (U60/show idx)

(U60/show 0) = "0"
(U60/show 1) = "1"
(U60/show 2) = "2"
(U60/show 3) = "3"
(U60/show 4) = "4"
(U60/show 5) = "5"
(U60/show 6) = "6"
(U60/show 7) = "7"
(U60/show 8) = "8"
(U60/show 9) = "9"
(U60/show n) = (String/concat (U60/show (/ n 10)) (U60/show (% n 10)))

(Serialize (Term/Lam bod))     = (Bits/O (Bits/O (Serialize bod)))
(Serialize (Term/App fun arg)) = (Bits/O (Bits/I (Bits/concat (Serialize fun) (Serialize arg))))
(Serialize (Term/Var idx))     = (SerializeVar (+ idx 1))

SerializeVar = λn switch n {
  0: (Bits/O Bits/E)
  _: (Bits/I (SerializeVar n-1))
}

#(IntToBits n) = (Bits/tail (Bits/reverse (IntToBits/go n)))

#(IntToBits/go 0) = Bits/E
#(IntToBits/go n) = if (% n 2) { (Bits/I (IntToBits/go (/ n 2))) } else { (Bits/O (IntToBits/go (/ n 2))) }

(IntToBits d i) = switch d {
  0: λt(t 0)
  _: λt(t (+ 1 (% i 2)) (IntToBits d-1 (/ i 2)))
}

# Equality
# --------

(Equal (Term/Lam a_bod)       (Term/Lam b_bod))       = (Equal a_bod b_bod)
(Equal (Term/App a_fun a_arg) (Term/App b_fun b_arg)) = (& (Equal a_fun b_fun) (Equal a_arg b_arg))
(Equal (Term/Var a_idx)       (Term/Var b_idx))       = (== a_idx b_idx)
(Equal a                      b)                      = 0

# Affinity Checker
# ----------------

(MarkUse i List/Nil)         = (Pair/New List/Nil 0)
(MarkUse 0 (List/Cons u us)) = (Pair/New (List/Cons (+ u 1) us) (if (== u 0) { 1 } else { 0 }))
(MarkUse i (List/Cons u us)) = 
  (Pair/get (MarkUse (- i 1) us) λus1 λusage
  (Pair/New (List/Cons u us1) usage))

(IsAffine (Term/Lam bod) ctx) =
  (Pair/get (IsAffine bod (List/Cons 0 ctx)) λctx λbod_af
  (Pair/New (List/tail ctx) bod_af))
(IsAffine (Term/App fun arg) ctx) =
  (Pair/get (IsAffine fun ctx) λctx λfun_af
  (Pair/get (IsAffine arg ctx) λctx λarg_af
  (Pair/New ctx (& fun_af arg_af))))
(IsAffine (Term/Var idx) ctx) = (MarkUse idx ctx)

(Halt term) = (if (Pair/snd (IsAffine term [])) { term } else { (Term/Var 0) })

# Substitution
# ------------

# Substitutes a var by a value in term
(Subst (Term/App fun arg) i val) = (Term/App (Subst fun i val) (Subst arg i val))
(Subst (Term/Lam bod)     i val) = (Term/Lam (Subst bod (+ i 1) (Shift val 0)))
(Subst (Term/Var idx)     i val) = (if (< idx i) { (Term/Var idx) } else { (if (== idx i) { val } else { (Term/Var (- idx 1)) }) })

# Shifts all free vars in term by 1
(Shift (Term/App fun arg) i) = (Term/App (Shift fun i) (Shift arg i))
(Shift (Term/Lam bod)     i) = (Term/Lam (Shift bod (+ i 1)))
(Shift (Term/Var idx)     i) = (if (>= idx i) { (Term/Var (+ idx 1)) } else { (Term/Var idx) })

# Evaluation
# ----------

(Reduce (Term/App fun arg)) = (ReduceApp (Reduce fun) arg)
(Reduce (Term/Lam bod))     = (Term/Lam bod)
(Reduce (Term/Var idx))     = (Term/Var idx)

(ReduceApp (Term/Lam bod)     x) = (Reduce (Subst bod 0 x))
(ReduceApp (Term/App fun arg) x) = (Term/App (Term/App fun arg) x)
(ReduceApp (Term/Var idx)     x) = (Term/App (Term/Var idx) x)

(Normal term) = (Normal/go (Reduce term))

(Normal/go (Term/App fun arg)) = (Term/App (Normal fun) (Normal arg))
(Normal/go (Term/Lam bod))     = (Term/Lam (Normal bod))
(Normal/go (Term/Var idx))     = (Term/Var idx)

# Search
# ------

Cond = λbs
  let tm = (Halt (DoParse bs))
  let k0 = (Equal (Normal (Term/App tm Tru)) Fal)
  let k1 = (Equal (Normal (Term/App tm Fal)) Tru)
  k0

Count = λd λl λi switch d {
  0: if (Cond (IntToBits l i)) { 1 } else { 0 }
  _: (+ (Count d-1 (+ l 1) (* i 2)) (Count d-1 (+ l 1) (+ (* i 2) 1)))
}

# Programs
# --------

Tru = (Term/Lam (Term/Lam (Term/Var 1)))
Fal = (Term/Lam (Term/Lam (Term/Var 0)))

# Main
# ----

#Main = (IntToBits 24 1234)

Main = (Count 22 0 0)
