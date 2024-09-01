package todin

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "core:testing"

// each buffer has to emulate the real screen ie, only say 48*105 or 48 cols and 105 rows

enter_alternate_screen :: proc() {
	os.write_string(os.stdin, "\e[?1049h")
	clear_screen()
	reset_cursor()
}

leave_alternate_screen :: proc() {
	os.write_string(os.stdin, "\e[?1049l")
}

clear_screen :: proc() {
	clear(&_buffer.data)
	os.write_string(os.stdin, "\e[2J")
}

delete_line :: proc() {
	for cell in _buffer.data[_buffer.pos.y] {
		delch()
	}
	//os.write_string(os.stdin, "\e[2K")
}

move_print :: proc(y, x: int, args: ..any) {
	move(y, x)
	print(..args)
}

print :: proc(args: ..any) {
	append_string(fmt.tprint(..args))
}

delch :: proc() {
	remove_rune()
	//os.write_string(os.stdin, "\e[1P")
}
