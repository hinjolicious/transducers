Red []

; closure: function [spec closures body][
	; obj-spec: copy []
	; parse closures [
		; any [
			; set w set-word! set v skip (append obj-spec reduce [w v])
			; | set w word! (append obj-spec reduce [to-set-word w get w])
		; ]
	; ]
	; func spec bind copy/deep body object obj-spec
; ]

; closure: function [spec closures body][
	; ctx: copy []
	; parse closures [ any [
		; set w set-word! set v skip (append ctx reduce [w v])
		; | set w word! (
			; append ctx either any-function? v: get w [
				; load mold reduce [to-set-word w :v]
			; ][
				; reduce [to-set-word w v]
			; ]
		; )
	; ]]
	; ?? ctx
	; func spec 
		; bind/copy ;append compose [ if (spec/1) = /self [return self] ] 
			; body 
		; object ctx
; ]

closure: func[spec closures body /local w v][
	ctx: copy[]
	parse closures [any[
		set w set-word! set v skip (append ctx reduce[w v])
		| set w word! (append ctx reduce[to-set-word w get w])
	]]
	func spec bind/copy body construct ctx ; <-- to build object from [to-set-word get w] !!!
]

capture: func[closures body][
	ctx: copy[]
	parse closures[any[
		set w set-word! set v skip (append ctx reduce[w v])
		| set w word! (append ctx reduce[to-set-word w get w])
	]]
	bind/copy body 	construct ctx ; <-- to build object from [to-set-word get w] !!!
]
cap: :capture

comment{ adder: func[n][
	func[x] cap[n][x + n]
]
add10: adder 10
probe add10 5

f: closure[x][n: 1000][n: n + x]
probe f 5

f: closure[x] reduce[b: copy []][append/only b x]
probe f [1]

foo: func[a][
	closure[b][a][
		closure[c][b][
			if c = /self [return self]
			?? b
			?? a
			?? c
		]
	]
] }
