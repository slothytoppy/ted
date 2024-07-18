package viewport

import "../deps/ncurses"
import "core:log"
import "core:strings"
import "core:testing"

Viewport :: struct {
	data: []byte, // view into some array of bytes
	pos:  [2]i32,
}

set_buffer :: proc(vp: ^Viewport, buffer: []byte) {
	vp.data = buffer
}

set_max_pos :: proc(vp: ^Viewport, max_x, max_y: i32) {
	vp.pos = [2]i32{max_x, max_y}
}

// doesnt account for flowing off the screen
render :: proc(vp: Viewport) {
	split := strings.split(string(vp.data), "\n")
	ncurses.curs_set(0)
	ncurses.move(0, 0)
	for i in 0 ..< vp.pos.y {
		ncurses.printw("%s", split[i])
		ncurses.move(i32(i) + 1, 0)
	}
	ncurses.curs_set(1)
	ncurses.refresh()
}
