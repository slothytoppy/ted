package editor

import "core:log"

Cursor :: struct {
	x, y: i32,
}

move_up :: proc(cursor: ^Cursor) {
	cursor.y = saturating_sub(cursor.y, 1, 0)
}

move_down :: proc(cursor: ^Cursor, viewport: Viewport) {
	cursor.y = saturating_add(cursor.y, 1, viewport.max_y)
	log.info(cursor, viewport)
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
