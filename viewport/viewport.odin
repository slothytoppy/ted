package viewport

import "../deps/ncurses"
import "core:log"
import "core:strings"
import "core:testing"

Viewport :: struct {
	data: []byte, // view into some array of bytes
	pos:  [4]i32,
}

set_buffer :: proc(vp: ^Viewport, buffer: []byte) {
	vp.data = buffer
}

set_max_pos :: proc(vp: ^Viewport, max_x, max_y: i32) {
	vp.pos = [4]i32{0, 0, max_x, max_y}
}

// doesnt account for flowing off the screen
render :: proc(vp: Viewport) {
	split := strings.split(string(vp.data), "\n")
	ncurses.curs_set(0)
	ncurses.move(0, 0)
	for i in 0 ..< vp.pos.w {
		ncurses.printw("%s", split[i])
		ncurses.move(i32(i) + 1, 0)
		log.info(i)
	}
	ncurses.curs_set(1)
	ncurses.move(vp.pos.y, vp.pos.x)
	ncurses.refresh()
}
