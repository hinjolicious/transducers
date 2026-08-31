Red []
; hinjolicious

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

comment{
adder: func[n][
	func[x] cap[n][x + n]
]
add10: adder 10
probe add10 5

f: closure[x][n: 1000][n: n + x]
probe f 5

f: closure[x] reduce[b: copy []][ append/only b x ]
probe f [1]

foo: func[a][
	closure[b][a][
		closure[c][b][
			if c = /self [return self]
			?? a
			?? b
			?? c
		]
	]
]
}
