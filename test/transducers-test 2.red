Red []

#include %../transducers.red
#include %comp-funcs.red
;#include %range.red

print "^/== TEST ==^/"

#include %test/comp-funcs.red
#include %test/range.red

; Usage Examples:

; 1. In-Memory Series Transduction

; Pipeline: Deduplicate globally -> Keep Evens -> Double them -> Batch into pairs (2)
; t-tap is a logging tap to examine the internal state inside transducer pipelines
xf: comp-funcs reduce [
	t-distinct				t-tap func[x][print["dis      :" x]]
	t-filter :even?			t-tap func[x][print["  fil    :" x]]
	t-map func[x][x * 2]	t-tap func[x][print["    map  :" x]]
	t-partition 2			t-tap func[x][print["      par:" mold x]]
]
print "^/FIRST RUN:"
probe transduce :xf :push-reducer copy[] [1 1 2 2 3 4 5 6 7 8 8]
print "^/SECOND RUN:"
probe transduce :xf :push-reducer copy[] [1 1 2 2 3 4 5 6 7 8 8 9 9 9 10 10 11 12]

; Output:
;FIRST RUN:
; dis      : 1
; dis      : 2
  ; fil    : 2
    ; map  : 4
; dis      : 3
; dis      : 4
  ; fil    : 4
    ; map  : 8
      ; par: [4 8]
; dis      : 5
; dis      : 6
  ; fil    : 6
    ; map  : 12
; dis      : 7
; dis      : 8
  ; fil    : 8
    ; map  : 16
      ; par: [12 16]
; [[4 8] [12 16]]

; SECOND RUN:
; dis      : 9
; dis      : 10
  ; fil    : 10
    ; map  : 20
; dis      : 11
; dis      : 12
  ; fil    : 12
    ; map  : 24
      ; par: [20 24]
; [[20 24]]

; NOTE: The internal state of the pipeline (here in t-distinct) is maintained between run.
; This is a normal behavior and desirable for many situations.
; To start a fresh, we have to re-run the whole pipeline creation too!
; The same way with with the 'dangling' buffer in t-partition, the normal way is to start a fresh is 
; by running the whole pipeline again!

print "^/== INTER-THREAD USAGE ==^/"

; 2. Inter-Thread / Co-routine Channel Usage

; Pipeline: Keep evens -> Drop first 1 item -> Take 3 results
print "Example 1:"
chan-xf: func [step [any-function!]] [
	b-filter: t-filter :even?
	b-drop:	  t-drop 1
	b-take:	  t-take 3
	b-filter b-drop b-take :step
]
chan: make-transducer-channel/pipeline :chan-xf

; Producer pushes raw messages
foreach n [1 2 3 4 5 6 7 8 9 10] [chan/send n]

; Consumer receives pre-processed results
print chan/receive	; Output: 4
print chan/receive	; Output: 6
print chan/receive	; 8
print chan/receive  ; none 

print "^/Example 2:"
chan-xf: func [step [any-function!]] [
	b-drop:	t-drop 2
	b-map:  t-map :uppercase
	b-take:	t-take 3
	b-drop b-map b-take :step
]
chan: make-transducer-channel/pipeline :chan-xf

; Producer pushes raw messages
foreach n ["if" "you" "see" "this" "message" "read" "it"] [chan/send n]

; Consumer receives pre-processed results
print chan/receive
print chan/receive
print chan/receive
print chan/receive