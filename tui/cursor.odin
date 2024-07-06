package tui

import "core:fmt"

enter_alt_buffer :: proc() {
	fmt.print("\e[?1049h")
}

exit_alt_buffer :: proc() {
	fmt.print("\e[?1049l")
}

reset_cursor :: proc() {
	fmt.print("\e[H")
}

erase_screen :: proc() {
	fmt.print("\e[2J")
}

move_cursor_up :: proc(lines_up: int) {
	fmt.printf("\e[%dA", lines_up)
}

move_cursor_down :: proc(lines_down: int) {
	str := fmt.tprint(lines_down)
	fmt.printf("\e[%dB", lines_down)
}

move_cursor_right :: proc(right: int) {
	fmt.printf("\e[%dC", right)
}

move_cursor_left :: proc(left: int) {
	fmt.printf("\e[%dD", left)
}

get_cursor_pos :: proc() {
	fmt.print("\e[6n")
}
