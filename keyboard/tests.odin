package keyboard

import "core:fmt"
import "core:log"
import "core:testing"

@(test)
is_ctrl_test :: proc(t: ^testing.T) {
	data: rune = 'Q'
	data &= 0x1f
	if !is_ctrl(data) {
		testing.fail_now(t, fmt.tprint("data:", data, "is not recognized as ^Q"))
	}
}

@(test)
is_readable_character_test :: proc(t: ^testing.T) {
	data := 'Q'
	log.info(typeid_of(type_of(data)))
}
