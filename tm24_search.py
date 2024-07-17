# //./tm24_search.js//
# TODO: port the program above to Python


import math

ADD_X = 0  # +X
ADD_Y = 1  # +Y
POW_2 = 2  # ^2
DIV_2 = 3  # /2

# Interpreter for the TM24 machine
def eval(n, code, x, y, state):
    if n == 0:
        return state
    else:
        oper = code % 4
        code = code // 4
        func = get_func(oper)
        return eval(n - 1, code, x, y, func(x, y, state))

# Given an instruction id, returns its function
def get_func(o):
    if o == ADD_X:
        return lambda x, y, s: (s + x) % (1 << 24)  # +X
    elif o == ADD_Y:
        return lambda x, y, s: (s + y) % (1 << 24)  # +Y
    elif o == POW_2:
        return lambda x, y, s: (s * s) % (1 << 24)  # ^2
    elif o == DIV_2:
        return lambda x, y, s: (s // 2) % (1 << 24)  # /2

# Sequential fragment of the search
def do_seq(n, i, s):
    for _ in range(n):
        test = eval(12, i, 9, 2, 0) == 68
        s += int(test)
        i += 1
    return s

# Parallel fragment of the search
def do_par(n, i):
    if n == 0:
        return do_seq(0x1000, i * 0x1000, 0)
    else:
        return do_par(n - 1, i * 2) + do_par(n - 1, i * 2 + 1)

# Searches 2^24 programs, looking for the Cantor Pairing Function
print(do_par(16, 0))

