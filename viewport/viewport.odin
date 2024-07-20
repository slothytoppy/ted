package viewport

import "../deps/ncurses"
import "core:bytes"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"

Pos :: struct {
	x, y, scroll_x, scroll_y: i32,
}

Viewport :: struct {
	// is the max x,y
	pos: Pos,
}

set_max_pos :: proc(vp: ^Viewport, max_x, max_y: i32) {
	vp.pos = {max_x, max_y, 0, 0}
}

render :: proc(vp: Viewport, data: []byte) {
	// TODO: line wrapping
	ncurses.move(0, 0)
	ncurses.erase()
	lines_count: i32 = cast(i32)bytes.count(data[:], {'\n'})
	lines_count = clamp(0, lines_count, vp.pos.y)
	buf := bytes.split(data[:], {'\n'})
	buf = buf[:lines_count]
	cursor: i32 = 0
	for i := vp.pos.scroll_y; i < vp.pos.scroll_y + vp.pos.y; i += 1 {
		i := cast(i32)i
		if i > cast(i32)len(buf) - 1 {
			break
		}
		line_len := min(cast(i32)len(buf[i]), vp.pos.x)
		ncurses.printw("%s", fmt.ctprint(cast(string)buf[i][:line_len]))
		ncurses.move(cursor + 1, 0)
		cursor += 1
	}
	ncurses.refresh()
}

should_scroll :: proc(#any_int y, max_y: i32) -> bool {
	return y > max_y
}
