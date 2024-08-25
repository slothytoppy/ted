package editor

import "../todin"
import "core:log"

editor_move_up :: proc(editor: ^Editor) {
	line := saturating_sub(editor.cursor.y, 1, 0)
	line_len := line_length(editor.buffer, line)
	x := editor.cursor.x
	log.info(line_len, line, editor.cursor.y)
	if x >= line_len {
		editor.cursor.virtual_x = x
		editor.cursor.x = line_len
	} else {
		if editor.cursor.virtual_x > 0 {
			editor.cursor.x = editor.cursor.virtual_x
			editor.cursor.virtual_x = 0
		}
	}
	move_up(&editor.cursor)
	editor_scroll_up(&editor.cursor, &editor.viewport)
}

editor_move_down :: proc(editor: ^Editor) {
	line := saturating_add(editor.cursor.y, 1, editor.viewport.max_y)
	line_len := line_length(editor.buffer, line)
	x := editor.cursor.x
	log.info(line_len, line, editor.cursor.y)
	if x >= line_len {
		editor.cursor.virtual_x = x
		editor.cursor.x = line_len
	} else {
		if editor.cursor.virtual_x > 0 {
			editor.cursor.x = editor.cursor.virtual_x
			editor.cursor.virtual_x = 0
		}
	}
	if editor.cursor.y > buffer_length(editor.buffer) {
		log.infof("%d is greater than %d", editor.cursor.y, line_len)
	}
	move_down(&editor.cursor, editor.viewport)
	editor_scroll_down(&editor.cursor, &editor.viewport, editor.buffer)
}

editor_scroll_up :: proc(cursor: ^Cursor, viewport: ^Viewport) {
	if cursor.y == 0 {
		viewport.scroll = saturating_sub(viewport.scroll, 1, 0)
	}
}

editor_scroll_down :: proc(cursor: ^Cursor, viewport: ^Viewport, buffer: Buffer) {
	if cursor.y >= viewport.max_y {
		if viewport.scroll + viewport.max_y <= buffer_length(buffer) {
			viewport.scroll = saturating_add(viewport.scroll, 1, buffer_length(buffer))
		}
	}
}

editor_move_left :: proc(editor: ^Editor) {
	line_length := line_length(editor.buffer, editor.cursor.y)
	if editor.cursor.x > line_length {
		return
	}
	move_left(&editor.cursor)
	todin.move_left()
}

editor_move_right :: proc(editor: ^Editor) {
	line_length := saturating_sub(line_length(editor.buffer, editor.cursor.y), 1, 0)
	x := editor.cursor.x
	if x >= line_length {
		return
	}
	move_right(&editor.cursor, editor.viewport)
	todin.move_right()
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
	line := saturating_sub(cursor.y, 1, 0)
	if is_line_empty(buffer^, line) {
		remove_line(buffer, line)
		move_up(cursor)
	} else {
		delete_char(buffer, cursor^)
		move_left(cursor)
	}
}

editor_remove_line_and_move_up :: proc(cursor: ^Cursor, buffer: ^Buffer) {
	line := saturating_sub(cursor.y, 1, 0)
	remove_line(buffer, line)
	move_up(cursor)
}
