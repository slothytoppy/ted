package todin

import "core:fmt"
import "core:os"

// each buffer has to emulate the real screen ie, only say 48*105 or 48 cols and 105 rows

enter_alternate_screen :: proc() {
	os.write_string(os.stdin, "\e[?1049h")
	clear_screen()
	reset_cursor()
}

leave_alternate_screen :: proc() {
	os.write_string(os.stdin, "\e[?1049l")
}

print :: proc(arg: rune) {
	fmt.print(arg)
}

delch :: proc() {
	os.write_string(os.stdin, "\e[1P")
}

clear_screen :: proc() {
	os.write_string(os.stdin, "\e[J")
}

clear_line :: proc() {
	os.write_string(os.stdin, "\e[2K")
}
