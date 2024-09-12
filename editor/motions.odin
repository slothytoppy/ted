package editor

import "./cursor"
import "./viewport"
import "buffer"
import "core:log"
import "core:strconv"
import "core:time"

@(private = "file")
Motion: buffer.Line
@(private = "file")
WAIT_TIME :: time.Millisecond * 200
@(private = "file")
LAST_CHECKED_TIME: time.Time

motion_append_rune :: proc(r: rune) {
	append(&Motion, buffer.Cell{datum = r})
}

clear_motion :: proc() {
	if len(Motion) >= 1 {
		clear(&Motion)
	}
}

trim_numbers :: proc() -> (string, int) {
	motion_str := buffer.line_to_string(Motion)
	num := strconv.atoi(motion_str)
	for r, i in motion_str {
		if r >= '0' && r <= '9' {
			ordered_remove(&Motion, i)
		}
	}
	return motion_str, num
}

check_motion :: proc(editor: ^Editor) {
	motion_str, num := trim_numbers()
	defer delete(motion_str)
	found_motion := false
	defer {
		if found_motion {
			clear_motion()
		}
	}
	switch motion_str {
	case "h":
		editor_move_left(editor.buffer, &editor.cursor)
		found_motion = true
	case "l":
		editor_move_right(editor.buffer, &editor.cursor, editor.viewport)
		found_motion = true
	case "k":
		editor_move_up(editor.buffer, &editor.cursor, &editor.viewport)
		found_motion = true
	case "j":
		editor_move_down(editor.buffer, &editor.cursor, &editor.viewport)
		found_motion = true
	case "^":
		move_to_line_start(&editor.cursor, editor.viewport)
		found_motion = true
	case "$":
		length := buffer.line_length(editor.buffer[editor.cursor.y])
		move_to_line_end(&editor.cursor, editor.viewport, saturating_sub(length, 1, 0))
		found_motion = true
	case "x":
		editor_backspace(&editor.cursor, &editor.buffer)
		found_motion = true
	case "dd":
		buffer.remove_line(&editor.buffer, editor.cursor.y)
		found_motion = true
	case "gg":
		editor.cursor.y = 0
		editor.cursor.x = 0
		editor.viewport.scroll = 0
		log.info(editor.cursor, editor.viewport)
		found_motion = true
	}
}

move_to_line_start :: proc(cursor: ^cursor.Cursor, viewport: viewport.Viewport) {
	if cursor.y > viewport.max_y {
		return
	}
	cursor.x = 0
}

move_to_line_end :: proc(cur: ^cursor.Cursor, viewport: viewport.Viewport, line_length: i32) {
	if cur.y > viewport.max_y {
		return
	}
	cur.x = line_length
}

editor_remove_line_and_move_up :: proc(cur: ^cursor.Cursor, buf: ^buffer.Buffer) {
	line := saturating_sub(cur.y, 1, 0)
	buffer.remove_line(buf, line)
	cursor.move_up(cur)
}
