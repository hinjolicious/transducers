Red []

; error display
error: func [msg loc /local e][
	e: make error! msg
	e/where: loc
	e/near: to word! append/dup "" "^^" (length? form loc) / 2
	do e
]
