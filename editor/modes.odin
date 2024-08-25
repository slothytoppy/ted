package editor

import "../todin"
import "core:log"

normal_mode :: proc(editor: ^Editor, event: Event) {
	event_to_string: string
	switch e in event {
	case Init:
	case todin.Event:
		event_to_string = todin.event_to_string(e)
		switch event_to_string {
		case "<c-s>":
			unimplemented("saving files")
		case "I":
			editor.mode = .insert
			log.info(editor.mode)
		case "k":
			editor_move_up(editor.buffer, &editor.cursor, &editor.viewport)
		case "j":
			editor_move_down(editor.buffer, &editor.cursor, &editor.viewport)
		case "h":
			editor_move_left(editor.buffer, &editor.cursor)
		case "l":
			editor_move_right(editor.buffer, &editor.cursor, editor.viewport)
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
			editor_move_left(editor.buffer, &editor.cursor)
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
	case Init:
	case Quit:
		break
	}
}

command_mode :: proc(editor: ^Editor, event: Event) {
	switch e in event {
	case todin.Event:
		switch event in e {
		case todin.Nothing, todin.FunctionKey, todin.Resize, todin.ArrowKey:
		case todin.BackSpace:
			remove_char_from_command_line()
		case todin.Enter:
			check_command()
		case todin.Key:
			if event.keyname == 'c' && event.control {
				editor.mode = .normal
				return
			}
			write_rune_to_command_line(event.keyname)
		case todin.EscapeKey:
		}
	case Init, Quit:
		break
	}
}
