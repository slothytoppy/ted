package cursor

import "../deps/ncurses/"

Cursor_Mode :: enum {
	hidden,
	normal,
	high_visibility,
}

Error :: enum {
	none,
	out_of_bounds,
}

Cursor :: struct {
	x, y, max_x, max_y: i32,
	mode:               Cursor_Mode,
}

move :: proc(cursor: ^Cursor, x, y: i32) -> Error {
	if x > cursor.max_x || y > cursor.max_y {
		return .out_of_bounds
	}
	cursor.x = x
	cursor.y = y
	ncurses.move(cursor.y, cursor.x)
	return .none
}
