USING: kernel io.files io.encodings.utf8 math.parser sequences math io arrays
       sequences.extras regexp strings locals math.matrices math.ranges vectors
       calendar calendar.parser variants combinators math.order sorting
       accessors hashtables assocs ;
IN: guard-timings


! Factor has structs!
TUPLE: line-item time-at event ;
C: <line-item> line-item

TUPLE: accumulator curr-guard time-asleep map ;
C: <accumulator> accumulator


! Factor (kind-of) has ADTs!
VARIANT: guard-event
  wake-up
  falls-asleep
  begins-shift: { guard-id } ;


: matches-wake ( str -- bool ) R/ wakes up$/ matches? ;
: matches-sleep ( str -- bool ) R/ falls asleep$/ matches? ;
: matches-shift-begin ( str -- bool ) R/ Guard #(\d+) begins shift$/ matches? ;

: get-guard-id ( str -- number ) R/ \d+/ first-match >string string>number ;

: get-event ( str -- event )
  { { [ dup matches-wake ] [ drop wake-up ] }
    { [ dup matches-sleep ] [ drop falls-asleep ] }
    { [ dup matches-shift-begin ] [ get-guard-id <begins-shift> ] }
  } cond ;


! Factor expects a seconds field too, so we'll append one first
: datetime-of ( str -- datetime ) ":00" append ymdhms>timestamp ;


: get-timestamp ( str -- timestamp remaining-str )
  dup
  R/ \[[^]]+\]/ first-match 1 17 rot subseq datetime-of swap
  R/ \[[^]]+\] / "" re-replace ;


! Map to timed events, then sort chronologically.
: parse-input-line ( str -- line-item ) get-timestamp get-event <line-item> ;

: chronological-sort ( seq-of-line-items -- sorted-seq )
  [| item1 item2 |
    item1 time-at>> timestamp>unix-time
    item2 time-at>> timestamp>unix-time
    <=>
  ] sort ;


: minute-value ( line-item -- minute ) time-at>> >time< drop swap drop ;


! For want of a defaultdict (which, lets be real, probably exists but I can't
! find it)
:: add-entry-to-map ( map key value -- )
  key map at dup
  [ value swap push ]
  [ drop 60 <vector> dup value swap push 
    key map set-at
  ]
  if ;

! Each guard ID maps to a list of timeranges when they were asleep. Completed map
! looks like {
!   1 -> [(15, 30), (12, 20)],
!   13 -> [(4, 18), (6, 21), (33, 45)]
!   ...
! }
:: assoc-by-guard-id ( accumulator line-item -- next )
  accumulator
  line-item event>> {
    { [ dup falls-asleep = ] [ drop line-item minute-value >>time-asleep ] }
    { [ dup begins-shift? ] [ guard-id>> >>curr-guard ] }
    { [ dup wake-up = ]
      [ 
        drop accumulator time-asleep>>
        line-item minute-value
        2array 

        accumulator map>> accumulator curr-guard>> rot add-entry-to-map

        0 >>time-asleep
      ]
    }
  } cond ;


! For every (k,v), sum the minutes of the "v pair" differences, then compare to
! the current max in the accum. If greater, (k, vsum) is the new accum. Else,
! keep the old accum.
:: guard-with-most-minutes ( accum sleeps -- accum )
  sleeps second 0 [ dup first swap second swap - + ] reduce dup
  accum second
  >
  [ sleeps first swap 2array ]
  [ drop accum ]
  if ;


! Given sleep shifts, create a frequency table.
:: count-frequencies ( hashtable interval -- hashtable )
  interval dup first swap second [a,b) [| val | val hashtable inc-at ] each
  hashtable ;


! Given a frequency table, find the most frequent we've got
:: key-with-max ( best-pair candidate -- best-pair )
  best-pair second
  candidate second
  <
  [ candidate ]
  [ best-pair ]
  if ;


! Handle the input, make a chronological list of events
"./input.txt" utf8 file-lines
[ parse-input-line ] map
chronological-sort

! Fold over it to produce a hash of guards -> [ sleep interval ]
dup rest swap
first event>> guard-id>>
0
100 <hashtable>
<accumulator>
[ assoc-by-guard-id ]
reduce
map>>

dup  ! we use the map again in part 2, keep it on the stack!

! Investigate that map to find the sleepiest guard
dup >alist
{ 0 0 }
[ guard-with-most-minutes ]
reduce
first

! Query that guard's sleep history, find the minute most frequently slept in.
dup rot at
60 <hashtable>
[ count-frequencies ]
reduce
>alist { 0 0 } [ key-with-max ] reduce first

"Part 1: Guard with the most sleep minutes is " write
swap dup number>string write
", sleeping most often on minute " write
swap dup number>string write  ", so the answer is " write
* number>string write
"\n" write
flush


! Part 2: we use the sleep mapping and instead make frequency tables of
! everyone's schedules, pick the one with the highest. A bit of a straight-up
! copy + paste, but I'm already behind :O

>alist
[
  dup first
  swap second 60 <hashtable> [ count-frequencies ] reduce
  >alist { 0 0 } [ key-with-max ] reduce
  2array
]
map

! So now we have an alist of the form [{id, {highest-minute, frequency}, ...]
! We've got *one more* maximizing reduce. I'll make a custom word for it, but
! really I should have generalized this by now.

:: max-guard-frequency ( best-set candidate -- best-set )
  best-set second second
  candidate second second
  <
  [ candidate ]
  [ best-set ]
  if ;

{ 0 { 0 0 } } [ max-guard-frequency ] reduce
dup first swap
second first

"Part 2: Guard with highest frequency in a single minute is " write
swap dup number>string write
", sleeping most often on minute " write
swap dup number>string write  ", so the answer is " write
* number>string write
"\n" write
flush
