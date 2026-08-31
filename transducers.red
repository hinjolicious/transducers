Red [
	Title:		"Red Transducer Library"
	Author:		"hinjolicious"
	File:		%transducers.red
	Purpose:	"Composable, single-pass data transformation pipelines for Red"
	Notes:		"Uses custom closure-based lexical scoping for environment capturing"
	Credits:	"Gemini AI, early ideas from Red/Sensei"
]

#include %closure.red


; ==============================================================================
; SECTION 1: REDUCERS & SENTINELS
; ==============================================================================

; Base reducer for collections/blocks
push-reducer: func[acc [block!] input][append/only acc input]
pr.: :push-reducer
; Base reducer for nested/batched items
; push-nested-reducer: func[acc [block!] input][append/only acc input]

; --- Early Termination (Reduced) Sentinels ---

reduced: func[val][reduce ['reduced val]]
reduced?: func[val][all [block? val 2 = length? val 'reduced = val/1]]
unreduced: func[val][either reduced? val [val/2][val]]


; ==============================================================================
; SECTION 2: TRANSDUCTION RUNNER
; ==============================================================================

transduce: func[
	xf	 [any-function!] ; Transducer pipeline
	step [any-function!] ; Base target reducer (e.g. :push-reducer)
	init 		 ; Target accumulator collection
	data [series!]		 ; Source series
][
	reducer: xf :step
	forall data [
		init: reducer init data/1
		if reduced? init [
			init: unreduced init
			break  ; Early exit if t-take signals reduced
		] ]
	init ]
tx.: :transduce


; ==============================================================================
; SECTION 3: TRANSDUCTION BUILDING BLOCKS (STATELESS)
; ==============================================================================

; t-map: Transforms items 1-to-1 using function f
t-map: func[f [any-function!]][
	closure[step][f][
		closure[acc input][step][
			step acc f input ]]]
tm.: :t-map

; t-filter: Retains items matching predicate pred
t-filter: func[pred [any-function!]][
	closure[step][pred][
		closure[acc input][step][
			either pred input [step acc input][acc] ]]]
tf.: :t-filter


; ==============================================================================
; SECTION 4: STATEFUL TRANSDUCERS
; ==============================================================================

; t-take: Retains first N items and signals early termination (reduced)
t-take: func[n [integer!]][
	closure[step][n][
		closure[acc input][step][
			either n > 0 [
				n: n - 1
				res: step acc input
				either n = 0 [reduced res][res]
			][reduced acc] ]]]
tt.: :t-take

; t-drop: Skips the first N items
t-drop: func[n [integer!]][
	closure[step][n][
		closure[acc input][step][
			either n > 0 [
				n: n - 1
				acc
			][step acc input] ]]]
td.: :t-drop

; t-dedupe: Removes consecutive duplicates
t-dedupe: func[][
	closure[step][last-val: 'empty][
		closure[acc input][step][
			either input = last-val [acc][
				last-val: input
				step acc input
			] ]]]
tdd.: :t-dedupe

; t-distinct: Removes global duplicates across entire dataset
t-distinct: func[][
	closure[step] reduce[seen: make hash! 16][
		closure[acc input][step][
			either find seen input [acc][
				append seen input
				step acc input
			] ]]]
tdt.: :t-distinct

; t-partition: Batches items into blocks of size N before sending downstream
t-partition: func[n [integer!]][
	closure[step] reduce['n buf: copy[]][
		closure[acc input][step][
			append buf input
			either n = length? buf [
				acc: step acc copy buf
				clear buf
				acc
			][acc] ]]]
tp.: :t-partition



; ==============================================================================
; SECTION 5: CO-ROUTINE CHANNEL ADAPTER
; ==============================================================================

make-transducer-channel: func[/pipeline xf [any-function!]][
	unless pipeline [
		xf: func[step][ closure[acc input][step][ step acc input ]]]
	make object! [
		queue: copy []
		push-step: func[acc input][
			either block? input [append/only acc input][append acc input]
			acc ]
		channel-reducer: xf :push-step
		send: func[msg][
			res: channel-reducer queue msg
			queue: unreduced res ]
		receive: func[][
			either empty? queue [none][take queue] ]]]
mtc.: :make-transducer-channel


COMMENT{ print "^/== TEST ==^/"

; Verification & Usage Examples
; 1. In-Memory Series Transduction

is-even?: :even?
double:	  func[x][x * 2]

; Pipeline: Deduplicate globally -> Keep Evens -> Double them -> Batch into pairs (2)
pipeline: func [step [any-function!]] [
	b-distinct:	 t-distinct
	b-filter:	 t-filter :even?
	b-map:		 t-map :double
	b-partition: t-partition 2
	
	b-distinct b-filter b-map b-partition :step
]


print "^/FIRST RUN:"
numbers: [2 2 4 1 6 4 8 2 10 12 13 14 15 16]
result: transduce :pipeline :push-reducer copy [] numbers
probe result
; Output: [[4 8] [12 16] [20 24]] }

COMMENT{ HOW TO CLEAR THE BUFFER?? }


COMMENT{ print "^/SECOND RUN:"
numbers: [3 8 9 2 2 4 1 6 4 8 2 10 12]
result: transduce :pipeline :push-reducer copy [] numbers
probe result


print "^/== INTER-THREAD USAGE ==^/"

; 2. Inter-Thread / Co-routine Channel Usage
; Pipeline: Keep evens -> Drop first 1 item -> Take 3 results
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
print chan/receive  ; none }

COMMENT{ chan-xf: func [step [any-function!]] [
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
print chan/receive }
