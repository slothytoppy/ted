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
	ncurses.move(0, 0)
	lines_count: i32 = 0
	line_len: i32 = 0
	start_idx: i32 = 0
	for line_len < cast(i32)len(vp.data) && lines_count < vp.pos.y {
		line_len += 1
		// \n at the end of the line
		if vp.data[line_len] == '\n' {
			line_len += 1
			// stupid thing i have to do because cstrings are nil terminated
			cstr := strings.clone_to_cstring(
				string(vp.data[start_idx:line_len]),
				context.temp_allocator,
			)
			ncurses.printw("%s", cstr)
			ncurses.move(lines_count + 1, 0)
			log.info(start_idx, line_len)
			lines_count += 1
			// modified at the end because its from last line length to the next lines length
			start_idx = line_len
		}
	}
}
