package editor

import "core:log"
import "core:mem"

@(require_results)
saturating_add :: proc(val, amount, max: $T) -> T {
	if val + amount < max {
		return val + amount
	}
	return max
}

@(require_results)
saturating_sub :: proc(val, amount, min: $T) -> T {
	if val - amount > min {
		return val - amount
	}
	return min
}
