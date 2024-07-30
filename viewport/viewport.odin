package viewport

// scroll command
Command :: enum {
	up,
	down,
}

Pos :: struct {
	cur_x, cur_y, max_x, max_y, scroll_y: i32,
}

Viewport :: struct {
	using pos: Pos,
}

set_max_pos :: proc(vp: ^Viewport, max_x, max_y: i32) {
	vp.pos = {
		max_x = max_x,
		max_y = max_y,
	}
}

get_current_line :: proc(viewport: Viewport) -> i32 {
	return viewport.cur_y
}

get_current_row :: proc(viewport: Viewport) -> i32 {
	return viewport.cur_x
}
