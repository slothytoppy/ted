package cursor

import "core:log"
import "core:testing"

Event :: enum {
	up,
	down,
	left,
	right,
}

Cursor :: struct {
	cur_x, cur_y, max_x, max_y: i32,
}

new :: proc(x, y, w, h: i32) -> Cursor {
	return {x, y, w, h}
}

move_cursor_to :: proc(old_pos: ^Cursor, #any_int col, row: i32) {
	old_pos.cur_y = col
	old_pos.cur_x = row
	old_pos^ = check_cursor_height(old_pos^)
	old_pos^ = check_cursor_width(old_pos^)
}

check_cursor_height :: proc(cursor: Cursor) -> Cursor {
	cur := new(cursor.max_x, cursor.max_y, cursor.max_x, cursor.max_y)
	if cursor.cur_y > cursor.max_y {
		cur.cur_y = cur.max_y
	}
	return cur
}

check_cursor_width :: proc(old_cursor: Cursor) -> Cursor {
	cursor := new(old_cursor.max_x, old_cursor.max_y, old_cursor.max_x, old_cursor.max_y)
	if old_cursor.cur_x > old_cursor.max_x {
		cursor.cur_x = cursor.max_x
	}
	return cursor
}

move_cursor_event :: proc(cursor: ^Cursor, ev: Event) {
	switch ev {
	case .up:
		if cursor.cur_y > 0 {
			cursor.cur_y -= 1
		}
	case .down:
		if cursor.cur_y < cursor.max_y {
			cursor.cur_y += 1
		}
	case .left:
		if cursor.cur_x > 0 {
			cursor.cur_x -= 1
		}
	case .right:
		if cursor.cur_x < cursor.max_x {
			cursor.cur_x += 1
		}
	}
}

should_scroll :: proc(cursor: Cursor, event: Event) -> bool {
	if cursor.cur_y == 0 && event == .up {
		return true
	} else if cursor.cur_y == cursor.max_y && event == .down {
		return true
	}
	return false
}

@(test)
cursor_test :: proc(t: ^testing.T) {
	cur := new(0, 0, 5, 10) // cursor starts at 0,0 with a max width and height of 5 and 10
	move_cursor_event(&cur, .down)
	if cur.cur_y != 1 {
		testing.fail(t)
	}
	move_cursor_event(&cur, .up)
	if cur.cur_y != 0 {
		testing.fail(t)
	}
	move_cursor_event(&cur, .right)
	if cur.cur_x != 1 {
		testing.fail(t)
	}
	move_cursor_event(&cur, .left)
	if cur.cur_x != 0 {
		testing.fail(t)
	}
	log.info(cur)
}
