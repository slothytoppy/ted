package viewport

import "../cursor"
import "../deps/ncurses"
import "core:log"
import "core:strings"

// scroll command
Command :: enum {
	up,
	down,
}

Pos :: struct {
	cur_x, cur_y, max_x, max_y, scroll_y: i32,
}

Viewport :: struct {
	cursor:    cursor.Cursor,
	using pos: Pos,
}

set_max_pos :: proc(vp: ^Viewport, max_x, max_y: i32) {
	vp.pos = {
		max_x = max_x,
		max_y = max_y,
	}
}

scroll_up :: proc(viewport: Viewport) -> (vp: Viewport) {
	vp = viewport
	if viewport.scroll_y > 0 {
		vp.scroll_y -= 1
		return vp
	}
	return viewport
}

scroll_down :: proc(viewport: Viewport, #any_int lines_count: i32) -> (vp: Viewport) {
	vp = viewport
	if vp.scroll_y + vp.max_y < lines_count {
		vp.scroll_y += 1
		return vp
	}
	return viewport
}

render :: proc(vp: ^Viewport, data: [dynamic][dynamic]byte) {
	if len(data) <= 0 {
		log.info("empty buffer")
		return
	}
	// erase so that i rerender to an empty screen, only needed for scrolling
	ncurses.erase()
	ncurses.curs_set(0)
	ncurses.move(0, 0)
	ncurses.refresh()

	if cursor.should_scroll(vp.cursor, .up) {
		vp^ = scroll_up(vp^)
	} else if cursor.should_scroll(vp.cursor, .down) {
		vp^ = scroll_down(vp^, len(data))
	}
	for line, i in data {
		i := cast(i32)i
		if i > vp.max_y + vp.scroll_y {
			break
		}
		line_len := min(cast(i32)len(data[i]), vp.max_y)
		ncurses.mvprintw(i, 0, "%s", strings.clone_to_cstring(string(line[:line_len])))
	}
	ncurses.curs_set(1)
	ncurses.refresh()
}
