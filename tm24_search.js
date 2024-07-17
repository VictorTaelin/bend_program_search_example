//./tm24_search.bend//
//./tm24_search.hs//

// TASK: convert the program above to JavaScript

const ADD_X = 0; // +X
const ADD_Y = 1; // +Y
const POW_2 = 2; // ^2
const DIV_2 = 3; // /2

// Interpreter for the TM24 machine
function Eval(n, code, x, y, state) {
  if (n === 0) {
    return state;
  } else {
    var oper = code % 4;
    var code = Math.floor(code / 4);
    var func = Func(oper);
    return Eval(n - 1, code, x, y, func(x, y, state));
  }
}

// Given an instruction id, returns its function
function Func(o) {
  switch (o) {
    case ADD_X:
      return (x, y, s) => (s + x) % (1 << 24); // +X
    case ADD_Y:
      return (x, y, s) => (s + y) % (1 << 24); // +Y
    case POW_2:
      return (x, y, s) => (s * s) % (1 << 24); // ^2
    case DIV_2:
      return (x, y, s) => Math.floor(s / 2) % (1 << 24); // /2
  }
}

// Sequential fragment of the search
function Seq(n, i, s) {
  if (n === 0) {
    return s;
  } else {
    var test = Eval(12, i, 9, 2, 0) === 68;
    return Seq(n - 1, i + 1, s + (test ? 1 : 0));
  }
}

// Parallel fragment of the search
function Par(n, i) {
  if (n === 0) {
    return Seq(0x1000, i * 0x1000, 0);
  } else {
    return Par(n - 1, i * 2 + 0) + Par(n - 1, i * 2 + 1);
  }
}

// Searches 2^24 programs, looking for the Cantor Pairing Function
const Main = Par(16, 0);
console.log(Main);
