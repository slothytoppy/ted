package editor

import "../todin"
import "core:log"

CursorEvent :: enum {
	none,
	up,
	down,
	left,
	right,
}

editor_move_up :: proc(buffer: Buffer, cursor: ^Cursor, viewport: ^Viewport) {
	line := saturating_sub(cursor.y, 1, 0)
	line_len := line_length(buffer, line)
	x := cursor.x
	log.info(line_len, line, cursor.y)
	if x >= line_len {
		cursor.virtual_x = x
		cursor.x = line_len
	} else {
		if cursor.virtual_x > 0 {
			cursor.x = cursor.virtual_x
			cursor.virtual_x = 0
		}
	}
	editor_scroll_up(cursor, viewport)
	move_up(cursor)
}

editor_move_down :: proc(buffer: Buffer, cursor: ^Cursor, viewport: ^Viewport) {
	line := saturating_add(cursor.y, 1, viewport.max_y)
	line_len := line_length(buffer, line)
	x := cursor.x
	log.info(line_len, line, cursor.y)
	if x >= line_len {
		cursor.virtual_x = x
		cursor.x = line_len
	} else {
		if cursor.virtual_x > 0 {
			cursor.x = cursor.virtual_x
			cursor.virtual_x = 0
		}
	}
	if cursor.y > buffer_length(buffer) {
		log.infof("%d is greater than %d", cursor.y, line_len)
	}
	editor_scroll_down(cursor, viewport, buffer)
	move_down(cursor, viewport^)
}

editor_move :: proc(event: CursorEvent, buffer: Buffer, cursor: ^Cursor, viewport: ^Viewport) {
	switch event {
	case .none:
	case .up:
		editor_move_up(buffer, cursor, viewport)
	case .down:
		editor_move_down(buffer, cursor, viewport)
	case .left:
		editor_move_left(buffer, cursor)
	case .right:
		editor_move_right(buffer, cursor, viewport^)
	}
}

editor_scroll_up :: proc(cursor: ^Cursor, viewport: ^Viewport) {
	if cursor.y == 0 {
		viewport.scroll = saturating_sub(viewport.scroll, 1, 0)
	}
}

editor_scroll_down :: proc(cursor: ^Cursor, viewport: ^Viewport, buffer: Buffer) {
	if cursor.y >= viewport.max_y - 1 {
		if viewport.scroll + viewport.max_y <= saturating_sub(buffer_length(buffer), 1, 0) {
			viewport.scroll = saturating_add(viewport.scroll, 1, buffer_length(buffer))
		}
	}
}

editor_move_left :: proc(buffer: Buffer, cursor: ^Cursor) {
	line_length := line_length(buffer, cursor.y)
	if cursor.x > line_length {
		return
	}
	move_left(cursor)
}

editor_move_right :: proc(buffer: Buffer, cursor: ^Cursor, viewport: Viewport) {
	line_length := saturating_sub(line_length(buffer, cursor.y), 1, 0)
	x := cursor.x
	if x >= line_length {
		return
	}
	move_right(cursor, viewport)
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

editor_backspace :: proc(cursor: ^Cursor, buffer: ^Buffer) {
	line := cursor.y
	log.debug(line)
	if is_line_empty(buffer^, line) {
		remove_line(buffer, line)
		move_up(cursor)
	} else {
		if cursor.y > buffer_length(buffer^) {
			return
		}
		delete_char(&buffer[cursor.y], cursor^)
		move_left(cursor)
	}
}

editor_remove_line_and_move_up :: proc(cursor: ^Cursor, buffer: ^Buffer) {
	line := saturating_sub(cursor.y, 1, 0)
	remove_line(buffer, line)
	move_up(cursor)
}
