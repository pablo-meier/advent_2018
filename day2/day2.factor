USING: kernel io.files io.encodings.utf8 math.parser sequences math io
       arrays hashtables assocs locals math.combinatorics ;
IN: checksum-calculator

! Produces a map with letters as keys and the number of times they appear as a
! value
: letter-frequencies ( str -- assoc )
  50 <hashtable>
  [| hash elt |  elt hash inc-at hash ]
  reduce ;

! Pushes true if the map says any letter has a value of 2.
: has-two ( assoc -- bool ) values [ 2 = ] any? ;

! Pushes true if the map says any letter has a value of 3.
: has-three ( assoc -- bool ) values [ 3 = ] any? ;

! Produces a pair of (0-1, 0-1) for whether or not it has occurrences of 2 or 3
! letters each.
:: two-or-three-pair ( hash -- pair )
  hash has-two [ 1 ] [ 0 ] if
  hash has-three [ 1 ] [ 0 ] if
  2array ;

:: sum-pairs ( prev accum -- result ) 
  prev first accum first +
  prev second accum second +
  2array ;
  
:: multiply-pair-values ( pair -- result )
  pair first pair second * ;

"./input.txt" utf8 file-lines
dup
[ letter-frequencies ] map
[ two-or-three-pair ] map 
{ 0 0 }
[ sum-pairs ]
reduce
multiply-pair-values
"Part 1: Checksum is " write number>string write "\n" write flush


! Cool, part 2 is a doozy again lol. We could in theory try to re-use the
! frequency counts, but they don't account for ordering. We'll write a string
! compare that looks for them positionally, generate all pairs with a
! permutations vocabulary, then find the pair with the common letters.

! Compares both strings side-by-side. We could short-circuit but I'm lazy.
: letters-off ( str1 str2 -- int ) 0 [ = [ 0 ] [ 1 ] if + ] 2reduce ;

: common-subsequence ( str1 str2 -- str3 )
  "" [| accum x y | accum x y = [ { x } ] [ "" ] if append ] 2reduce ;


! At this point in the stack, we have a list of all the strings. Generate all
! pairs, then compare letters off, find the pair where it's 1.
2 <combinations>
[| arr | arr first arr second letters-off 1 = ]
filter
first
dup first swap second
common-subsequence
 
"Part 2: Two common substring is " write write "\n" write flush
