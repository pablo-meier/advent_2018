USING: kernel io.files io.encodings.utf8 math.parser sequences math io arrays
       sequences.extras regexp strings locals math.matrices math.ranges vectors ;
IN: santa-fabric


! Each rectangle is represented as a 5-tuple { id left top width height }
: parse-input-line ( str -- tuple ) 
  R/ [^0-9]+/ re-split
  [ >string ] map
  rest [ string>number ] map ;


: fifth ( seq -- seq ) 4 swap nth ;


! Given a rectangle, generate a sequence of { row col } to visit
:: pairs-to-visit ( rect -- pairs-seq )
  rect fourth rect fifth * <vector>

  rect third
  dup rect fifth +
  [a,b)
  [| row |
    rect second
    dup rect fourth +
    [a,b)
    [| col |
      dup { row col } swap push
    ] each 
  ] each ;
  

:: get-and-increment-value-at ( pair matrix -- )
  pair first matrix nth
  dup pair second swap nth 1 +
  swap pair second swap set-nth ;


! get, increment the value at matrix[row][col]
:: apply-rectangle ( matrix rect-spec -- matrix )
  rect-spec second
  [ matrix get-and-increment-value-at ] each
  matrix ;


"./input.txt" utf8 file-lines [ parse-input-line dup pairs-to-visit 2array ] map
dup ! For Part 2
1000 1000 zero-matrix
[ apply-rectangle ]
reduce
dup ! For Part 2

[ [ 1 > ] filter length ] map
sum

"Part 1: There are " write number>string write " squares with too many tiles assigned\n" write flush


! Now we do the traversal again on the solved matrix and stop if we're able to
! traverse the whole thing and see 1. Top of the stack currently has
! ( recspec-sequence matrix -- )

:: is-1-at? ( pair matrix -- bool )
  pair first matrix nth
  pair second swap nth
  1 = ;

:: is-failing-rectangle? ( matrix rect-spec -- matrix bool )
  rect-spec second
  [ matrix is-1-at? ] all? not 
  matrix swap ;

swap
[ is-failing-rectangle? ]
drop-while
first first first
"Part 2: Tile with ID " write number>string write " does not overlap\n" write flush
drop
