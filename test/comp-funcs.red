Red []
; Functional Composition

; simple-case: only expect functions returning values
; comp-funcs: func[ff][
	; func[x /local e] compose append collect [
		; foreach e ff [keep (get e)]
	; ] 'x
; ]

; complex-case: allow composing multiple functions that accept another functions
comp-funcs: func[ff][
	func[x /local e] compose append collect [
		foreach e ff [
			keep (either (word? :e) [get e][:e]) 
		]
	] to-get-word 'x
]

COMMENT{ log-sin-cos: comp-funcs [log-e sin cos]
print log-sin-cos 0.5 
; -0.2624090041749859

f1: func[f][f * 2]
f2: func[f][:f]
f3: func[f][:f]
ff: comp-funcs [f1 f2 f3]
probe ff func[][10]
;== 20 }
