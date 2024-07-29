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

get_current_line :: proc(viewport: Viewport) -> i32 {
	return viewport.cur_y
}

get_current_row :: proc(viewport: Viewport) -> i32 {
	return viewport.cur_x
}
