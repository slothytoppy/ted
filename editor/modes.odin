package editor

import "../todin"
import "buffer"
import "core:fmt"
import "core:log"

normal_mode :: proc(editor: ^Editor, event: Event) -> Event {
	//event_string := event_to_string(event)
	switch e in event {
	case Init:
	case Quit:
	case todin.Event:
		#partial switch event in e {
		case todin.Key:
			if !event.control {
				if event.keyname == ':' {
					editor.mode = .command
				}
				if event.keyname == '-' {

				}
				motion_append_rune(event.keyname)
			}
		}
	}
	check_motion(editor)
	return event
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
