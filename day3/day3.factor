USING: kernel io.files io.encodings.utf8 math.parser sequences math io
       regexp strings locals math.matrices math.ranges ;
IN: santa-fabric


! Each rectangle is represented as a 5-tuple { id left top width height }
: parse-input-line ( str -- tuple ) 
  R/ [^0-9]+/ re-split
  [ >string ] map
  rest [ string>number ] map ;


: fifth ( seq -- seq ) 4 swap nth ;


! for row in range(top, top + height)
!   for col in range(left, left + width)
!      get, increment the value at matrix[row][col]
:: apply-rectangle ( matrix rect -- matrix )
  rect third
  dup rect fifth +
  [a,b)
  [| row |
    rect second
    dup rect fourth +
    [a,b)
    [| col |
      row matrix nth
      dup col swap nth 1 +
      swap col swap set-nth
    ] each
  ] each
  matrix ;


"./input.txt" utf8 file-lines [ parse-input-line ] map
1000 1000 zero-matrix
[ apply-rectangle ]
reduce

[ [ 1 > ] filter length ] map
sum

"Part 1: There are " write number>string write " squares with too many tiles assigned\n" write flush



