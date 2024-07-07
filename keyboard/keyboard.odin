package keyboard

is_ctrl :: #force_inline proc(key: rune) -> bool {
	if key == key & 0x1F {
		return true
	}
	return false
}

is_readable_character :: #force_inline proc(key: rune) -> bool {
	if !is_ctrl(key) && !is_shift(key) {
		return true
	}
	return false
}

is_shift :: #force_inline proc(key: rune) -> bool {
	return false
}
