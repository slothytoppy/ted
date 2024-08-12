package editor

Cursor :: struct {
	x, y: i32,
}

move_up :: proc(cursor: ^Cursor) {
	cursor.y = saturating_sub(cursor.y, 1, 0)
}

move_down :: proc(cursor: ^Cursor, viewport: Viewport) {
	cursor.y = saturating_add(cursor.y, 1, viewport.max_y)
}

move_left :: proc(cursor: ^Cursor) {
	cursor.x = saturating_sub(cursor.x, 1, 0)
}

move_right :: proc(cursor: ^Cursor, viewport: Viewport) {
	cursor.x = saturating_add(cursor.x, 1, viewport.max_x)
}
