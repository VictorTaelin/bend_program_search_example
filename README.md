## Bend - Discrete Program Search - Simple Example

This repository aims to investigate how Bend could be used to accelerate program
search on GPUs, in a near future. Initially, I implemented a full Lambda
Calculus interpreter, based on explicit substitutions, and searched for BLC that
pass a given test. The interpreter itself was not meant to be fast; it was just
meant to compare HVM's performance against other runtimes. Good and bad news:

- ✓ It works! HVM can run the full λC on 32k+ threads with 0 concurrency errors.

- ✓ Near-ideal parallelism on CPU! It reached around ~1.6k MIPS on M3 Max.

- ✗ On GPU, warp divergence ruined performance, from ~50k to just 1k MIPS.

Unlike the CPU runtime, which is stable and predictable, our GPU version is
still very experimental, and extremely sensible to small changes in code. There
is still a long way before HVM-CUDA is stable and mature enough for this kind of
application. Meanwhile, to illustrate the concept, I've designed a simpler
language to perform program search on.

## The TM24 machine

TM24 is a 24-bit machine with a state, 2 inputs (X, Y) and 4 instructions:

```
- ADD_X: adds X to the state
- ADD_Y: adds Y to the state
- POW_2: squares the state
- DIV_2: halves the state
```

Our goal is to find for a program that implements the Cantor Pairing function:

> f(x,y) = ((x+y+1)*(x+y))/2+y

This is done by enumerating ~16 million programs, and looking for one that
passes the following test:

> f(2,9) == 68

This search has been implemented as a simple Haskell, JavaScript and Bend
files, with around ~50 lines each. 

## Results

| Language / Runtime | Time    | Hardware        |
| ------------------ | ------- | --------------- |
| Python (CPython)   | 529.42s | Apple M3 Max    |
| JavaScript (V8)    |  74.27s | Apple M3 Max    |
| Haskell (GHC)      |  13.18s | Apple M3 Max    |
| Bend (HVM)         |   5.43s | NVIDIA RTX 4090 |

## Conclusion

Bend wasn't capable of parallelizing well on the full λ-Calculus yet, due to
immaturity of the CUDA runtime. In a simpler language, though, it achieved ideal
parallelism, allowing it to beat all SOTA runtimes on this specific benchmark,
by using an RTX 4090 to accelerate the computation. On single-core performance,
Bend is still sub-par, because:

- 1. HVM is still an young project, relative to decades-old runtimes.

- 2. HVM still has NO optimizer: it is equivalent to `-O0`.

- 3. HVM still has NO compiler: it almost entirely runs interpreted.

- 4. HVM still misses some essential optimizations (like native constructors).

As HVM and Bend continue to mature and optimize, they have the potential to
become powerful tools to accelerate symbolic computations such as discrete
program search, which, currently, can only run in CPUs.

## Note

The algorithms used here are illustrative and not meant to be efficient. A fast
λ-Calculus evaluator uses HOAS rather than explicit substitutions, for example.
Moreover, there is a promising new technique to perform fast program search by
exploiting superposition (fan nodes) on Interaction Combiantors. There are
compelling results which we aim to publish in the future.