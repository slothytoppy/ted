package editor

import "../todin"
import "buffer"
import "core:log"

CursorEvent :: enum {
	none,
	up,
	down,
	left,
	right,
}

editor_move_up :: proc(buf: buffer.Buffer, cursor: ^Cursor, viewport: ^Viewport) {
	line := saturating_sub(cursor.y, 1, 0)
	line_len := buffer.line_length(buf, line)
	x := cursor.x
	log.debug(line_len, line, cursor.y)
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

editor_move_down :: proc(buf: buffer.Buffer, cursor: ^Cursor, viewport: ^Viewport) {
	line := saturating_add(
		cursor.y,
		1,
		min(viewport.max_y, cast(i32)saturating_sub(len(buf), 1, 0)),
	)
	line_len := buffer.line_length(buf, line)
	if line_len < 0 {
		return
	}
	x := cursor.x
	log.debug(line_len, line, cursor.y)
	if x > line_len {
		cursor.virtual_x = x
		cursor.x = line_len
	} else {
		if cursor.virtual_x > 0 {
			cursor.x = cursor.virtual_x
			cursor.virtual_x = 0
		}
	}
	editor_scroll_down(cursor, viewport, buf)
	move_down(cursor, viewport^)
}

editor_move :: proc(event: CursorEvent, buf: buffer.Buffer, cursor: ^Cursor, viewport: ^Viewport) {
	switch event {
	case .none:
	case .up:
		editor_move_up(buf, cursor, viewport)
	case .down:
		editor_move_down(buf, cursor, viewport)
	case .left:
		editor_move_left(buf, cursor)
	case .right:
		editor_move_right(buf, cursor, viewport^)
	}
}

editor_scroll_up :: proc(cursor: ^Cursor, viewport: ^Viewport) {
	if cursor.y == 0 {
		viewport.scroll = saturating_sub(viewport.scroll, 1, 0)
	}
}

editor_scroll_down :: proc(cursor: ^Cursor, viewport: ^Viewport, buf: buffer.Buffer) {
	buff_len := saturating_sub(buffer.buffer_length(buf), 1, 0)
	if cursor.y >= viewport.max_y - 1 {
		if viewport.scroll + viewport.max_y < buff_len {
			viewport.scroll = saturating_add(viewport.scroll, 1, buff_len)
		}
	}
}

editor_move_left :: proc(buf: buffer.Buffer, cursor: ^Cursor) {
	line_length := buffer.line_length(buf, cursor.y)
	if cursor.x > line_length {
		return
	}
	move_left(cursor)
}

editor_move_right :: proc(buf: buffer.Buffer, cursor: ^Cursor, viewport: Viewport) {
	line_length := saturating_sub(buffer.line_length(buf, cursor.y), 1, 0)
	x := cursor.x
	if x >= line_length {
		return
	}
	move_right(cursor, viewport)
}

editor_backspace :: proc(cursor: ^Cursor, buf: ^buffer.Buffer) {
	line := cursor.y
	log.debug(line)
	if buffer.is_line_empty(buf^, line) {
		return
	} else {
		if cursor.y > buffer.buffer_length(buf^) {
			return
		}
		remove_rune(buf, cursor^)
		move_left(cursor)
	}
}

editor_should_move_right :: proc(event: Event) -> bool {
	#partial switch e in event {
	case todin.Event:
		#partial switch event in e {
		case todin.Key:
			if !event.control && event.keyname == 'l' {
				return true
			}
		case todin.ArrowKey:
			#partial switch event {
			case .right:
				return true
			case:
				return false
			}
		}
	}
	return false
}
