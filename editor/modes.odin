package editor

import "../deps/todin"
import "core:log"

normal_mode :: proc(editor: ^Editor, event: Event) {
	event_to_string: string
	switch e in event {
	case todin.Event:
		event_to_string = todin.event_to_string(e)
		switch event_to_string {
		case "I":
			editor.mode = .insert
			log.info(editor.mode)
		case "k":
			editor_move_up(editor)
		case "j":
			editor_move_down(editor)
		case "h":
			editor_move_left(editor)
		case "l":
			editor_move_right(editor)
		case ":":
			editor.mode = .command
		case "backspace":
			editor_move_left(editor)
		}
	case Quit:
		break
	}
}

insert_mode :: proc(editor: ^Editor, event: Event) {
	editor_event_to_string: string
	switch e in event {
	case todin.Event:
		editor_event_to_string = todin.event_to_string(e)
		switch editor_event_to_string {
		case "enter":
			append_line(&editor.buffer, saturating_sub(editor.cursor.y, 1, 0))
			move_down(&editor.cursor, editor.viewport)
		case "<c-c>":
			editor.mode = .normal
		case "backspace":
			line := saturating_sub(editor.cursor.y, 1, 0)
			if val, ok := line_length(editor.buffer, line); ok {
				if val > 0 {
					delete_char(&editor.buffer, editor.cursor)
					move_left(&editor.cursor)
				} else {
					remove_line(&editor.buffer, line)
					move_up(&editor.cursor)
				}
			}
		}
		#partial switch event in e {
		case todin.Key:
			append_rune_to_buffer(&editor.buffer, editor.cursor, event.keyname)
			move_right(&editor.cursor, editor.viewport)
		}
	case Quit:
		break
	}
}
