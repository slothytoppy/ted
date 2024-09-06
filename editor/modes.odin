package editor

import "../todin"
import "buffer"
import "core:fmt"
import "core:log"

normal_mode :: proc(editor: ^Editor, event: Event) -> Event {
	event_string: string
	event_string = event_to_string(event)
	switch e in event {
	case Init:
	case todin.Event:
		switch event_string {
		case "I":
			editor.mode = .insert
			log.info(editor.mode)
		case "up":
			editor_move_up(editor.buffer, &editor.cursor, &editor.viewport)
		case "down":
			editor_move_down(editor.buffer, &editor.cursor, &editor.viewport)
		case "left":
			editor_move_left(editor.buffer, &editor.cursor)
		case "right":
			editor_move_right(editor.buffer, &editor.cursor, editor.viewport)
		case ":":
			editor.mode = .command
		case "^":
			move_to_line_start(&editor.cursor, editor.viewport)
		case "$":
			length := saturating_sub(buffer.line_length(editor.buffer, editor.cursor.y), 1, 0)
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
		case "-":
		}
	case Quit:
		return Quit{}
	}
	return nil
}

insert_mode :: proc(editor: ^Editor, event: Event) -> Event {
	editor_event_to_string: string
	switch e in event {
	case todin.Event:
		#partial switch event in e {
		case todin.Enter:
			buffer.append_line(&editor.buffer, editor.cursor.y)
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
				return nil
			}
			append_rune(&editor.buffer, editor.cursor, event.keyname)
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
		return Quit{}
	}
	return nil
}

command_mode :: proc(editor: ^Editor, event: Event) -> Event {
	switch e in event {
	case todin.Event:
		switch event in e {
		case todin.Nothing, todin.FunctionKey, todin.Resize, todin.ArrowKey:
		case todin.BackSpace:
			remove_char_from_command_line(&editor.command_line)
		case todin.Enter:
			switch commands in check_command(&editor.command_line) {
			case ErrorMsg:
				write_error_to_command_line(&editor.command_line, commands)
			case Commands:
				editor.mode = .normal
				switch command in commands {
				case Quit:
					return Quit{}
				case EditFile:
					buf := buffer.read_file(command.file_name)
					if buf == nil {
						write_error_to_command_line(
							&editor.command_line,
							fmt.tprintf("file %s does not exist", command.file_name),
						)
						editor.mode = .command
						return nil
					}
					buffer.delete_buffer(&editor.buffer)
					editor.current_file = command.file_name
					editor.buffer = buf
					log.info(editor.current_file)
				case SaveAs:
					buffer.write_buffer_to_file(editor.buffer, command.file_name)
					delete(command.file_name)
				case Save:
					buffer.write_buffer_to_file(editor.buffer, editor.current_file)
				}
			}
		case todin.Key:
			if event.keyname == 'c' && event.control {
				editor.mode = .normal
				clear_command_line(&editor.command_line)
				return nil
			}
			write_rune_to_command_line(&editor.command_line, event.keyname)
		case todin.EscapeKey:
		}
	case Init:
		break
	case Quit:
		return Quit{}
	}
	return nil
}
