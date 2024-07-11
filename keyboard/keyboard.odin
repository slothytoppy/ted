package keyboard

import "../cursor"
import ncurses "../deps/ncurses/src"
import "core:fmt"
import "core:sync/chan"
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
	if !is_ctrl(key) {
		return true
	}
	return false
}

@(test)
is_readable_character_test :: proc(t: ^testing.T) {
	data := 'Q'
	if is_ctrl(data) {
		testing.fail_now(t, fmt.tprint("data:", data, "is not a printable character"))
	}
}

// receives a char from the input thread
get_char :: proc(channel: chan.Chan(rune)) -> (key: Maybe(rune), ok: bool) #optional_ok {
	key = chan.try_recv(channel) or_return
	return key, true
}
