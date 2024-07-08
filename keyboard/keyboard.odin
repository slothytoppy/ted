package keyboard

import "../deps/ncurses"
import "core:fmt"
import "core:testing"

is_ctrl :: #force_inline proc(key: rune) -> bool {
	if key == key & 0x1F {
		return true
	}
	return false
}

@(test)
is_ctrl_test :: proc(t: ^testing.T) {
	data: rune = 'Q'
	data &= 0x1f
	if !is_ctrl(data) {
		testing.fail_now(t, fmt.tprint("data:", data, "is not recognized as ^Q"))
	}
}

is_readable_character :: #force_inline proc(key: rune) -> bool {
	if !is_ctrl(key) && !is_shift(key) {
		return true
	}
	return false
}

@(test)
is_readable_character_test :: proc(t: ^testing.T) {
	data := 'Q'
	if is_ctrl(data) || is_shift(data) {
		testing.fail_now(t, fmt.tprint("data:", data, "is not a printable character"))
	}
}

// not sure if thers a use for this
is_shift :: #force_inline proc(key: rune) -> bool {
	if key == ncurses.KEY_SLEFT || key == ncurses.KEY_SRIGHT {
		return true
	}
	return false
}

@(test)
is_shift_test :: proc(t: ^testing.T) {
	if is_shift(ncurses.KEY_SLEFT) && !is_shift('q') {
		return
	}
	testing.fail_now(t, "failed to recognize left shift as shift")
}
