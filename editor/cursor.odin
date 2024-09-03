package editor

import "core:log"

Cursor :: struct {
	virtual_x, x, y: i32,
}

init_cursor :: proc(y: i32 = 1, x: i32 = 0) -> Cursor {
	return Cursor{y = y, x = x}
}

move_up :: proc(cursor: ^Cursor) {
	cursor.y = saturating_sub(cursor.y, 1, 0)
}

move_down :: proc(cursor: ^Cursor, viewport: Viewport) {
	cursor.y = saturating_add(cursor.y, 1, viewport.max_y - 1)
	log.debug(cursor, viewport)
}

move_left :: proc(cursor: ^Cursor) {
	cursor.x = saturating_sub(cursor.x, 1, 0)
}

move_right :: proc(cursor: ^Cursor, viewport: Viewport) {
	cursor.x = saturating_add(cursor.x, 1, viewport.max_x)
}

move_to_next_line_start :: proc(cursor: ^Cursor, viewport: Viewport) {
	cursor.y = saturating_add(cursor.y, 1, viewport.max_y)
	cursor.x = 0
}
