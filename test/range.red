Red []

#include %error.red

range: function [
	"Generate a range of numbers with step"
	range-block [block!] "[<start> <stop> <step>]"
	/local start stop step
][
	if any [empty? range-block  (length? range-block) < 2  (length? range-block) > 3][
		error "range-block must be [start stop] or [start stop step]" rejoin ["range " mold range-block]
	]
	forall range-block [
		if not number? range-block/1 [
			error "start stop step must be numbers" rejoin ["range " mold range-block]
		]
	]		
	set [start stop step] reduce range-block
	either none? step [
		either start > stop [ 
			collect [i: start while [i >= stop][keep i i: i - 1]]
		][
			collect [i: start while [i <= stop][keep i i: i + 1]]
		]
	][
		if step = 0 [
			error "range's step must be non-zero!" rejoin ["range " mold range-block]
		]
		i: start
		either step > 0 [
			collect [ while [i <= stop][
				keep either float? step [round/to i step][i]
				i: i + step
			]]
		][
			collect [ while [i >= stop][
				keep either float? step [round/to i step][i]
				i: i + step
			]]
		]
	]
]

comment {
print "foreach i range [1 5] [probe i] =>"
foreach i range [1 5] [probe i]

print "foreach i range [2 -2 -0.5] [probe i] =>"
foreach i range [2 -2 -0.5] [probe i]
}
