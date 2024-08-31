package editor

Motion :: Buffer

init_motion :: proc() -> (motion: Motion) {
	append(&motion, Line{})
	return motion
}

check_motion :: proc(motion: Motion) {
	if len(motion) >= 2 {
		panic("Motion data structure has too many Lines, should only have one Line")
	}
}

move_to_line_start :: proc(cursor: ^Cursor, viewport: Viewport) {
	if cursor.y > viewport.max_y {
		return
	}
	cursor.x = 0
}

move_to_line_end :: proc(cursor: ^Cursor, viewport: Viewport, line_length: i32) {
	if cursor.y > viewport.max_y {
		return
	}
	cursor.x = line_length
}

editor_remove_line_and_move_up :: proc(cursor: ^Cursor, buffer: ^Buffer) {
	line := saturating_sub(cursor.y, 1, 0)
	remove_line(buffer, line)
	move_up(cursor)
}
