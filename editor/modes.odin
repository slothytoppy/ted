package editor

import "../deps/todin"
import "core:log"

normal_mode :: proc(editor: ^Editor, event: Event) {
	event_to_string: string
	defer delete(event_to_string)
	switch e in event {
	case todin.Event:
		event_to_string = todin.event_to_string(e)
		switch event_to_string {
		case "I":
			editor.mode = .insert
			log.info(editor.mode)
		case "k":
			move_up(&editor.cursor)
		case "j":
			move_down(&editor.cursor, editor.viewport)
		case "h":
			move_left(&editor.cursor)
		case "l":
			move_right(&editor.cursor, editor.viewport)
		case ":":
			editor.mode = .command
		case "backspace":
			move_left(&editor.cursor)
		}
	case Quit:
		break
	}
}

insert_mode :: proc(editor: ^Editor, event: Event) {
	editor_event_to_string: string
	defer delete(editor_event_to_string)
	switch e in event {
	case todin.Event:
		editor_event_to_string = todin.event_to_string(e)
		switch editor_event_to_string {
		case "<c-c>":
			editor.mode = .normal
		case "backspace":
			delete_char(&editor.buffer, editor.cursor)
			move_left(&editor.cursor)
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
