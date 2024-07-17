package cursor

Event :: enum {
	up,
	down,
	left,
	right,
}

Cursor :: #type [2]i32

new :: proc(x, y: i32) -> Cursor {
	return {x, y}
}

// doesnt account for any max_x or max_y, only prevents x and y from becoming negative
move_cursor_to :: proc(old_pos: ^Cursor, new_pos: Cursor) {
	old_pos := old_pos
	old_pos^ = new_pos.xy
}

// doesnt account for any max_x or max_y, only prevents x and y from becoming negative
move_cursor_event :: proc(cursor: ^Cursor, ev: Event) {
	switch ev {
	case .up:
		if cursor.y > 0 {
			cursor.y -= 1
		}
	case .down:
		if cursor.y > 0 {
			cursor.y += 1
		}
	case .left:
		if cursor.x > 0 {
			cursor.x -= 1
		}
	case .right:
		if cursor.x > 0 {
			cursor.x += 1
		}
	}
}
