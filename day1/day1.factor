USING: kernel io.files io.encodings.utf8 math.parser sequences math io
       sets hash-sets locals ;
IN: frequency-reducer

! Part 1 is pretty easy: read the input lines, convert them all to ints,
! then perform a summation. We don't even need reduce!

"./input.txt" utf8 file-lines
[ string>number ] map 
dup
sum
"Part 1: Frequency offset is " write number>string write "\n" write flush


! For Part 2, we'll need slightly more complicated logic. At this point, the
! stack contains the initial list of input ints.
!
! - We'll need early exit, in case we find the repeated value somewhere in the
!   middle of the sequence. For this, I'll be manually implementing the reduce
!   rather than use the standard sequence combinator, which will only terminate
!   at the end of the list.
! 
! - We'll need to be able to loop back to the beginning of the initial input
!   in case we don't find a repeat in the first cycle through. For this, I'll
!   keep a top-level reference to the input list and use that as the reduce
!   input when hitting the empty case, rather than the defaulting of terminating.
!
! - I'll need to keep track of values that I've seen before, so I'll also have a
!   top-level reference to a <hash-set> that I'll use to check.
! 
! This is using a few Factor features I've never really played before: I try to
! avoid variables generally, but looking at the `hash-sets` vocabulary, it seems
! like it relies on being referred by variable: most of the operations don't
! push a set reference back onto the stack, meaning it gets "lost" unless you
! have some other references to it. To achieve the above, let's define a few
! words, some using the `::` operator.


! I'll program Scheme in any language! `uncons` takes a sequence and pushes two
! new elements on the stack: the first element of the sequence at the top, and a
! sequence containing the rest of the elements.
: uncons ( seq -- tailseq first ) 1 cut swap first ;

! After an uncons, we have what we need to perform the operation for a reduce
! step. Made much easier with variables once I finally understood them lol. 
:: apply-reduce-step ( accum op tail head -- accum op rst )
  accum head op call( x y -- z )
  op tail ;

! Now that we can perform a single step, we can now perform it recursively and
! modify the termination condition, and check for repeats.
:: modified-reduce ( whole-input seq seen-before accum op -- accum )
  seq empty?
  [ whole-input whole-input seen-before accum op modified-reduce ]
  [ accum op seq uncons apply-reduce-step
    pick
    seen-before
    ?adjoin
    [| accum op rst | whole-input rst seen-before accum op modified-reduce ]
    [ drop drop ]
    if
  ]
  if ;

dup
100 <hash-set>
0
[ + ]
modified-reduce

"Part 2: Frequency offset is " write number>string write "\n" write flush
