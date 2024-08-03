package viewport

// scroll command
Direction :: enum {
	none,
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

should_scroll :: proc(viewport: Viewport, direction: Direction) -> Direction {
	if viewport.cur_y <= 0 && direction == .up {
		return .up
	} else if viewport.cur_y > viewport.max_y && direction == .down {
		return .down
	}
	return .none
}
