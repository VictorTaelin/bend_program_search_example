ADD_X = 0 # +X
ADD_Y = 1 # +Y
POW_2 = 2 # ^2
DIV_2 = 3 # /2

# Interpreter for the TM24 machine
def Eval(n, code, x, y, state):
  switch n:
    case 0:
      return state
    case _:
      oper = code % 4
      code = code / 4
      func = Func(oper)
      return Eval(n-1, code, x, y, func(x, y, state))

# Given an instruction id, returns its function
def Func(o):
  p = o % 2
  o = o / 2
  q = o % 2
  u = 2
  switch p:
    case 0:
      switch q:
        case 0: # +X
          return λx: λy: λs: s + x
        case _: # ^2
          return λx: λy: λs: s * s
    case _:
      switch q:
        case 0: # +Y
          return λx: λy: λs: s + y
        case _: # /2
          # FIXME: changing this to /2 causes catastrophic branch divergence
          return λx: λy: λs: s / u

# Sequential fragment of the search
def Seq(n, i, s):
  switch n:
    case 0:
      return s
    case _:
      test = Eval(12, i, 9, 2, 0) == 68
      return Seq(n-1, i+1, s + test)

# Parallel fragment of the search
def Par(n, i):
  switch n:
    case 0:
      return Seq(0x1000, i * 0x1000, 0)
    case _:
      return Par(n-1, i*2+0) + Par(n-1, i*2+1)

# Searches 2^24 programs, looking for the Cantor Pairing Function
Main = (Par 16 0)
