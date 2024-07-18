package cursor

import "core:log"
import "core:testing"

Event :: enum {
	up,
	down,
	left,
	right,
}

Cursor :: #type [4]i32

new :: proc(x, y, w, h: i32) -> Cursor {
	return {x, y, w, h}
}

// doesnt account for any max_x or max_y, only prevents x and y from becoming negative
move_cursor_to :: proc(old_pos: ^Cursor, new_pos: Cursor) {
	old_pos := old_pos
	old_pos^ = new_pos.xywz
}

check_cursor_height :: proc(cursor: Cursor) -> Cursor {
	cur := new(cursor.x, cursor.y, cursor.w, cursor.z)
	if cursor.y > cursor.z {
		cur.y = cur.z
	}
	return cur
}

check_cursor_width :: proc(cursor: ^Cursor) {
	if cursor.x > cursor.w {
		cursor.x = cursor.w
	}
}

move_cursor_event :: proc(cursor: ^Cursor, ev: Event) {
	switch ev {
	case .up:
		if cursor.y > 0 {
			cursor.y -= 1
		}
	case .down:
		if cursor.y < cursor.z {
			cursor.y += 1
		}
	case .left:
		if cursor.x > 0 {
			cursor.x -= 1
		}
	case .right:
		if cursor.x < cursor.w {
			cursor.x += 1
		}
	}
	log.info("pos:", cursor)
}

@(test)
cursor_test :: proc(t: ^testing.T) {
	cur := new(0, 0, 5, 10) // cursor starts at 0,0 with a max width and height of 5 and 10
	move_cursor_event(&cur, .down)
	if cur.y != 1 {
		log.info(cur)
		testing.fail(t)
	}
	move_cursor_event(&cur, .up)
	if cur.y != 0 {
		log.info(cur)
		testing.fail(t)
	}
}
