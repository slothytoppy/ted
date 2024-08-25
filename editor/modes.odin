package editor

import "../todin"
import "core:log"

normal_mode :: proc(editor: ^Editor, event: Event) {
	event_to_string: string
	switch e in event {
	case todin.Event:
		event_to_string = todin.event_to_string(e)
		switch event_to_string {
		case "<c-s>":
			unimplemented("saving files")
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
		case "^":
			move_to_line_start(&editor.cursor, editor.viewport)
		case "$":
			length := saturating_sub(line_length(editor.buffer, editor.cursor.y), 1, 0)
			move_to_line_end(&editor.cursor, editor.viewport, saturating_sub(length, 1, 0))
		case "o":
			unimplemented()
		case "x":
			editor_backspace(&editor.cursor, &editor.buffer)
		case "d":
		// no queue system so this is kinda bad since in vim its `dd` and not just `d`
		//	editor_remove_line_and_move_up(&editor.cursor, &editor.buffer)
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
		#partial switch event in e {
		case todin.Enter:
			append_line(&editor.buffer, saturating_sub(editor.cursor.y, 1, 0))
			move_to_next_line_start(&editor.cursor, editor.viewport)
		case todin.BackSpace:
			editor_backspace(&editor.cursor, &editor.buffer)
		case todin.Key:
			editor_event_to_string = todin.event_to_string(e)
			if event.control == true {
				switch editor_event_to_string {
				case "<c-c>":
					editor.mode = .normal
				}
				return
			}
			append_rune_to_buffer(&editor.buffer, editor.cursor, event.keyname)
			move_right(&editor.cursor, editor.viewport)
			log.info(
				"cursor:",
				editor.cursor,
				"len:",
				len(editor.buffer[saturating_sub(editor.cursor.y, 1, 0)]),
			)
		}
	case Quit:
		break
	}
}
