package viewport

import "../deps/ncurses"
import "core:strings"

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
	ncurses.move(0, 0)
	for s, i in strings.split(string(vp.data), "\n") {
		if i > cast(int)vp.pos.y {
			break
		}
		ncurses.printw("%s", s)
		ncurses.move(cast(i32)i + 1, 0)
	}
	ncurses.refresh()
}
