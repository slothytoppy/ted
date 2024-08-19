package editor

import "../deps/todin"

editor_move_up :: proc(editor: ^Editor) {
	move_up(&editor.cursor)
	todin.move_up()
	if editor.cursor.y == 0 {
		editor.viewport.scroll = saturating_sub(editor.viewport.scroll, 1, 0)
	}
}

editor_move_down :: proc(editor: ^Editor) {
	if editor.cursor.y > cast(i32)len(editor.buffer.data) - 1 {
		return
	}
	move_down(&editor.cursor, editor.viewport)
	todin.move_down()
	if editor.cursor.y >= editor.viewport.max_y {
		if editor.viewport.scroll + editor.viewport.max_y <= cast(i32)len(editor.buffer.data) - 1 {
			editor.viewport.scroll = saturating_add(
				editor.viewport.scroll,
				1,
				cast(i32)len(editor.buffer.data) - 1,
			)
		}
	}
}

editor_move_left :: proc(editor: ^Editor) {
	move_left(&editor.cursor)
	todin.move_left()
}

editor_move_right :: proc(editor: ^Editor) {
	if editor.cursor.x > cast(i32)len(editor.buffer.data[saturating_sub(editor.cursor.y, 1, 0)]) {
		return
	}
	move_right(&editor.cursor, editor.viewport)
	todin.move_right()
}
