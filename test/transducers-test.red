Red []

#include %transducers.red
#include %comp-funcs.red
#include %range.red

p>: :print
p> "== 1. Base Reducer Test =="
; A reducer is just a function that takes an accumulator (where we store results) and an input, combines them, and returns the updated accumulator.
p> "push-reducer (pr.) test:"
a: copy[]
foreach i range[10 50 10][ probe a: pr. a i ]
; [10]
; [10 20]
; [10 20 30]
; [10 20 30 40]
; [10 20 30 40 50]

p> "^/== 2. Testing a Transducer directly =="
p> "t-map (tm.) test:"
; t-map is a function generator:
    ; You give it a transformation function (like x * 3).
    ; It gives back a function that waits for a step function (a reducer).
    ; Once it gets that reducer, it returns a brand new modified reducer.
; Let's test t-map by building a modified reducer manually without any wrapper:
; 1. Define transformation
triple: func[x][x * 3]
; 3. Generate a mapper step builder
map-builder: tm. :triple
; 4. Pass our base reducer (pr.) into it to get a NEW reducer!
map-reducer: map-builder :pr.
; 5. Test it manually!
a: copy[]
foreach i range[1 5][ probe a: map-reducer a i ]
; [3]
; [3 6]
; [3 6 9]
; [3 6 9 12]
; [3 6 9 12 15]
; NOTE: map-reducer is a reducer with the signature [acc input]. But before it calls push-reducer, it transforms input using triple.

p> "^/== 3. Testing t-filter (tf.) directly =="
; 1. Build the filter reducer manually
filter-builder: tf. :even?
filter-reducer: filter-builder :pr.
a: copy[]
foreach i range[1 5][ probe a: filter-reducer a i ]
; []
; [2]
; [2]
; [2 4]
; [2 4]
; Key Takeaway So Far
; Notice how filter-reducer and map-reducer have the exact same signature: [acc input].
; Because both modified reducers expect [acc input], we can nest them inside each other!

p> "^/== 4. Transduce (tx.) Runner =="
; Combine transducers manually or via helper
; Process flow is left-to-right: data --> filter-builder --> map-builder --> result
combined-xf: func[step][
	filter-builder map-builder :step
]
probe tx. :combined-xf :pr. copy[] range [1 10]
; [6 12 18 24 30]

p> "^/== 5. Using Functional Composition (comp-funcs) =="
; comp-funcs is a functional composition function that can handle multiple-functions that take another functions as arguments
probe tx. comp-funcs reduce[
	tf. :even?
	tm. :triple
] :pr. copy[] range [1 10]
; [6 12 18 24 30]

p> "^/== 6. t-take (tt.) =="
probe tx. comp-funcs reduce[ tt. 3 ] :pr. copy[] [a b c d e]
; [a b c]

p> "^/== 7. Early Termination Support =="
; t-take (tt.) is built with an early termination support, so receiving a large input will not process through all of them if we only need just a few of it.
probe tx. comp-funcs reduce[
	tf. :even?
	tm. :triple
	tt. 2
] :pr. copy[] range [1 15]
; [6 12]
; What happened behind the scenes:
    ; 1 → Odd (skipped)
    ; 2 → Even → 2 * 3 = 6 → Taken (1 left)
    ; 3 → Odd (skipped)
    ; 4 → Even → 4 * 3 = 12 → Taken (0 left → signals reduced)
    ; Loop stops immediately at index 4! Numbers 5 through 15 were never evaluated or iterated over.

p> "^/== 8. t-drop (td.) =="
; t-drop drops (ignores) the first N items before letting all subsequent items pass straight through to downstream reducers.
; probe tx. comp-funcs reduce[ td. 2 ] :pr. copy[] [a b c d]
probe tx. td. 2 :pr. copy[] [a b c d] ; only one reducer, no-need comp-funcs here!
; [c d]

p> "^/== 9. Testing t-filter (tf.), t-drop (td.), and t-take (tt.) =="
probe tx. comp-funcs reduce[
	tf. :even?
	tm. :triple
	td. 2
	tt. 2
] :pr. copy[] range[1 20]
; [18 24]
; Step-by-Step Execution Trace:
    ; 2 → even → 2 * 3 = 6 → Dropped (drop count: 1 remaining)
    ; 4 → even → 4 * 3 = 12 → Dropped (drop count: 0 remaining)
    ; 6 → even → 6 * 3 = 18 → Passed drop → Taken (take count: 1 remaining) → [18]
    ; 8 → even → 8 * 3 = 24 → Passed drop → Taken (take count: 0 remaining → reduced) → [18 24]
    ; Loop halts early at number 8!
	
p> "^/== 10. Deduplication: t-dedupe (tdd.) and t-distinct (tdt.) =="
p> "t-dedupe (tdd.) will filter out consecutive duplications"
probe tx. tdd. :pr. copy[] [1 1 2 2 3 1 1 4 4 4 5] ; no-need comp-funcs!
; [1 2 3 1 4 5]
p> "t-distinct (tdt.) will filter out all duplications"
probe tx. tdt. :pr. copy[] [1 1 2 2 3 1 1 4 4 4 5] ; no-need comp-funcs!
; [1 2 3 4 5]

p> "^/== 11. Full Pipeline Test =="
probe tx. comp-funcs reduce[
	tdt.
	tf. :even?
	tm. func[x][x * 2]
	tt. 3
] :pr. copy[] [2 2 4 1 6 4 8 2 10 12 14]
; [4 8 12]
; Execution Flow:
    ; 2 → Seen: [2] → Even → 2 * 2 = 4 → Taken [4] (2 left)
    ; 2 → Already in seen → Skipped
    ; 4 → Seen: [2 4] → Even → 4 * 2 = 8 → Taken [4 8] (1 left)
    ; 1 → Seen: [2 4 1] → Odd → Skipped
    ; 6 → Seen: [2 4 1 6] → Even → 6 * 2 = 12 → Taken [4 8 12] (0 left → reduced)
    ; Loop terminates early at index 5.

p> "^/== 12. Stateful Transducer: t-partition (tp.) =="
; A batching transducer (often called t-partition or t-buffer) collects individual items into a fixed-size block (N) before flushing the entire chunk downstream to the next step.
probe tx. tp. 3 :pr. copy[] range[1 10]
; [[1 2 3] [4 5 6] [7 8 9]] ; 10 is still in the buffer!

p> "^/== 13. Usage in Co-routines: make-transducer-channel (mtc.) =="

; Using t-partition on a co-routine channel or queue, reduces context switching and mutex locking by allowing the producer to push items continuously, but waking up consumer co-routines only when a full batch is ready.

; 1. Define channel with an embedded transducer pipeline
chan-pipeline: comp-funcs reduce[
	tf. :even?
	tm. func[x][x * 2]
	tdt.
	tp. 2
]
work-channel: mtc./pipeline :chan-pipeline

; 2. Producer thread sends raw messages
foreach i append range[1 10] range [5 15][
	print ["Producer: sent" i]
	work-channel/send i
]

; 3. Consumer thread receive pre-processed data
foreach i range[1 5][
	print ["Consumer: received" mold work-channel/receive]
]

; Producer: sent 1
; Producer: sent 2
; Producer: sent 3
; Producer: sent 4
; Producer: sent 5
; Producer: sent 6
; Producer: sent 7
; Producer: sent 8
; Producer: sent 9
; Producer: sent 10
; Producer: sent 5
; Producer: sent 6
; Producer: sent 7
; Producer: sent 8
; Producer: sent 9
; Producer: sent 10
; Producer: sent 11
; Producer: sent 12
; Producer: sent 13
; Producer: sent 14
; Producer: sent 15
; Consumer: received [4 8]
; Consumer: received [12 16]
; Consumer: received [20 24]
; Consumer: received none
; Consumer: received none

; Key Performance Benefits for Inter-Thread Queues
    ; Reduced Lock Contention: Invalid or filtered messages are dropped before acquiring queue mutexes/atomic locks.
    ; Batching: A stateful transducer like t-partition or t-buffer can group N small co-routine events into a single vector payload before triggering a thread wake-up, dramatically reducing context switching.
    ; Early Shutdown: A t-take transducer can automatically signal reduced to close the channel queue when N messages are produced.


p> "^/== 14. Other Usage Examples =="
; 1. Define channel with an embedded transducer pipeline
chan-pipeline: comp-funcs reduce[
	tf. :even?
	tm. func[x][x * 2]
	tp. 3
]

chan-push-step: func[queue batch][ append/only queue batch ]
batch-reducer: chan-pipeline :chan-push-step

queue: copy[]
; 2. Producer thread sends raw messages
foreach i range[1 20][
	print ["Producer: sent" i]
	queue: batch-reducer queue i
]
probe queue

; Producer: sent 1
; Producer: sent 2
; Producer: sent 3
; Producer: sent 4
; Producer: sent 5
; Producer: sent 6
; Producer: sent 7
; Producer: sent 8
; Producer: sent 9
; Producer: sent 10
; Producer: sent 11
; Producer: sent 12
; Producer: sent 13
; Producer: sent 14
; Producer: sent 15
; Producer: sent 16
; Producer: sent 17
; Producer: sent 18
; Producer: sent 19
; Producer: sent 20
; [[4 8 12] [16 20 24] [28 32 36]]

; composing transducers manually:
xf-pipeline: func[step][
	bf: tf. :even?
	bm: tm. :triple
	bt: tt. 2
	bf bm bt :step
]
data: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
probe tx. :xf-pipeline :pr. copy[] data

; or using functional composition:
data: [1 2 2 3 2 4 2 5 6 7 8 9 10 11 12 13 14 15]
probe tx. comp-funcs reduce [
	tdt.		; 1. Distinct globally -> [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
	tf. :even?	; 2. Keep Evens		  -> [2 4 6 8 10 12 14]
	td. 1		; 3. Drop First 1	  -> [4 6 8 10 12 14]
	tm. :triple ; 4. Triple Values	  -> [12 18 24 30 36 42]
	tt. 5		; 5. Take First 5	  -> [12 18 24 30 36]
] :pr. copy [] data
; Output: [12 18 24 30 36]

; The 4 Transducer Families
; Category					Role														Examples						State Needed?
; 1. One-to-One Transformers	Modify an item and pass it down immediately.					t-map							None
; 2. One-to-Zero (Filters)	Keep or drop items based on condition or identity.			t-filter, t-dedupe, t-distinct	None (or tracking set)
; 3. One-to-Many (Expanders)	Take 1 item and output multiple items (or flatten arrays).	t-cat (concatenate), t-mapcat	None
; 4. Structural / Stateful	Change the timing, quantity, or grouping of items.			t-take, t-drop, t-partition		Counter or array buffer
