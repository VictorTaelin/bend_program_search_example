-- Interpreter for the TM24 machine
eval :: Int -> Int -> Int -> Int -> Int -> Int
eval 0 _    _ _ state = state
eval n code x y state =
  let oper  = code `mod` 4
      code' = code `div` 4
      func  = get_func oper
  in eval (n-1) code' x y (func x y state)

-- Given an instruction id, returns its function
get_func :: Int -> (Int -> Int -> Int -> Int)
get_func 0 = \x _ s -> (s + x) `mod` (2^24) -- +X
get_func 1 = \_ y s -> (s + y) `mod` (2^24) -- +Y
get_func 2 = \_ _ s -> (s ^ 2) `mod` (2^24) -- ^2
get_func 3 = \_ _ s -> (s `div` 2) `mod` (2^24) -- /2

-- Sequential fragment of the search
do_seq :: Int -> Int -> Int -> Int
do_seq 0 _ s = s
do_seq n i s =
  let test = eval 12 i 9 2 0 == 68
  in do_seq (n-1) (i+1) (s + fromEnum test)

-- Parallel fragment of the search
do_par :: Int -> Int -> Int
do_par 0 i = do_seq 0x1000 (i * 0x1000) 0
do_par n i = do_par (n-1) (i*2) + do_par (n-1) (i*2+1)

-- Searches 2^24 programs, looking for the Cantor Pairing Function
main :: IO ()
main = print $ do_par 16 0
