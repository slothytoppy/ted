package editor

import "../todin"
import "./cursor"
import "./viewport"
import "buffer"
import "core:log"

CursorEvent :: enum {
	none,
	up,
	down,
	left,
	right,
}

editor_move_up :: proc(buf: buffer.Buffer, cur: ^cursor.Cursor, viewport: ^viewport.Viewport) {
	line := saturating_sub(cur.y, 1, 0)
	line_len := buffer.buffer_line_length(buf, line)
	x := cur.x
	log.debug(line_len, line, cur.y)
	if x >= line_len {
		cur.virtual_x = x
		cur.x = line_len
	} else {
		if cur.virtual_x > 0 {
			cur.x = cur.virtual_x
			cur.virtual_x = 0
		}
	}
	editor_scroll_up(cur, viewport)
	cursor.move_up(cur)
}

editor_move_down :: proc(buf: buffer.Buffer, cur: ^cursor.Cursor, viewport: ^viewport.Viewport) {
	if cur.y + 1 > viewport.max_y || cur.y + 1 > buffer.buffer_length(buf) {
		return
	}
	line := cur.y + 1
	line_len := buffer.buffer_line_length(buf, line)

	if line_len < 0 {
		return
	}

	x := cur.x
	log.debug(line_len, line, cur.y)
	if x >= line_len {
		cur.virtual_x = x
		cur.x = line_len
	} else {
		if cur.virtual_x > 0 {
			cur.x = cur.virtual_x
			cur.virtual_x = 0
		}
	}
	editor_scroll_down(cur, viewport, buf)
	cursor.move_down(cur, viewport^)
}

editor_move :: proc(
	event: CursorEvent,
	buf: buffer.Buffer,
	cursor: ^cursor.Cursor,
	viewport: ^viewport.Viewport,
) {
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

editor_scroll_up :: proc(cursor: ^cursor.Cursor, viewport: ^viewport.Viewport) {
	if cursor.y == 0 {
		viewport.scroll = saturating_sub(viewport.scroll, 1, 0)
	}
}

editor_scroll_down :: proc(
	cursor: ^cursor.Cursor,
	viewport: ^viewport.Viewport,
	buf: buffer.Buffer,
) {
	buff_len := saturating_sub(buffer.buffer_length(buf), 1, 0)
	if cursor.y >= viewport.max_y - 1 {
		if viewport.scroll + viewport.max_y < buff_len {
			viewport.scroll = saturating_add(viewport.scroll, 1, buff_len)
		}
	}
}

editor_move_left :: proc(buf: buffer.Buffer, cur: ^cursor.Cursor) {
	line_length := buffer.buffer_line_length(buf, cur.y)
	if cur.x > line_length {
		return
	}
	cursor.move_left(cur)
}

editor_move_right :: proc(buf: buffer.Buffer, cur: ^cursor.Cursor, viewport: viewport.Viewport) {
	line_length := saturating_sub(buffer.buffer_line_length(buf, cur.y), 1, 0)
	x := cur.x
	if x >= line_length {
		return
	}
	cursor.move_right(cur, viewport)
}

editor_backspace :: proc(cur: ^cursor.Cursor, buf: ^buffer.Buffer) {
	line := cur.y
	log.debug(line)
	if buffer.is_line_empty(buf^, line) {
		return
	} else {
		if cur.y > buffer.buffer_length(buf^) {
			return
		}
		remove_rune(buf, cur^)
		cursor.move_left(cur)
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
