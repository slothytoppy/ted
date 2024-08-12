package editor

import "../buffer"
import "../deps/todin"
import "core:flags"
import "core:log"
import "core:os"

default_init :: proc() -> (editor: Editor) {
	cli_args: Args_Info
	if e := parse_cli_arguments(&cli_args); e != .none {
		#partial switch e {
		case .help_request:
			flags.write_usage(os.stream_from_handle(os.stdout), Args_Info, "ted")
			os.exit(0)
		case:
			os.exit(1)
		}
	}
	editor.viewport.max_y, editor.viewport.max_x = todin.get_max_cursor_pos()
	if cli_args.file == "" {
		editor.buffer = make(buffer.Buffer, 1)
	} else {
		abs, errno := os.absolute_path_from_relative(cli_args.file)
		editor.buffer = load_buffer_from_file(abs)
		if errno == os.ERROR_NONE {
			editor.current_file = abs
			log.info(editor.current_file)
		} else {
			log.info("error:", errno, "obtaining absolute path from file:", cli_args.file)
		}
	}
	return editor
}

updater :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: Event) {
	todin_event: todin.Event
	#partial switch e in editor_event {
	case todin.Nothing:
		todin_event = todin.Nothing{}
		event = todin_event
	case todin.ArrowKey:
		switch e {
		case .up:
			editor.cursor.y = saturating_sub(editor.cursor.y, 1, editor.viewport.min_y)
			todin.move_up()
		case .down:
			editor.cursor.y = saturating_add(editor.cursor.y, 1, editor.viewport.max_y)
			todin.move_down()
		case .left:
			editor.cursor.x = saturating_sub(editor.cursor.x, 1, editor.viewport.min_x)
			todin.move_left()
		case .right:
			editor.cursor.x = saturating_add(editor.cursor.x, 1, editor.viewport.max_x)
			todin.move_right()
		}
	case todin.Key:
		if todin.event_to_string(e) == "<c-q>" {
			return Quit{}
		}
	}
	switch editor.mode {
	case .normal:
		return handle_normal_mode(editor, editor_event)
	case .insert:
		return handle_insert_mode(editor, editor_event)
	}
	return event
}

handle_normal_mode :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: todin.Event) {
	#partial switch e in editor_event {
	case:
		switch todin.event_to_string(e) {
		case "backspace":
			editor.cursor.x = saturating_sub(editor.cursor.x, 1, editor.viewport.min_x)
			todin.move_left()
		case "<c-s>":
			buffer.write_buffer_to_file(editor.buffer, editor.current_file)
			log.info("wrote to:", editor.current_file)
		case "I":
			editor.mode = .insert
		case "h":
			editor.cursor.x = saturating_sub(editor.cursor.x, 1, editor.viewport.min_x)
		case "k":
			editor.cursor.y = saturating_sub(editor.cursor.y, 1, editor.viewport.min_y)
		case "j":
			editor.cursor.y = saturating_add(editor.cursor.y, 1, editor.viewport.max_y)
		case "l":
			editor.cursor.x = saturating_add(editor.cursor.x, 1, editor.viewport.max_x)
		case "^":
			editor.cursor.x = 0
		case "$":
			editor.cursor.x = cast(i32)len(editor.buffer[editor.cursor.y]) - 1
		case "O":
			log.info("creating newline above is: unimplemented")
		case "o":
			log.info("creating newline below is: unimplemented")
		}
	}
	return event
}

handle_insert_mode :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: Event) {
	#partial switch e in editor_event {
	case todin.BackSpace:
		if editor.cursor.x <= cast(i32)len(editor.buffer[editor.cursor.y + 1]) {
			if editor.cursor.x > 0 {
				delete_char(editor)
				return Refresh{}
			}
		}
	case todin.Key:
		switch todin.event_to_string(e) {
		case "<c-c>":
			editor.mode = .normal
		case "enter":
			tmp := make(buffer.Buffer, len(editor.buffer) + 1)
			for line, i in editor.buffer {
				i := cast(i32)i
				if i < editor.cursor.y {
					append(&tmp[i], ..line[:])
				} else if i == editor.cursor.y {
					append(&tmp[i], ..line[:min(editor.cursor.x, cast(i32)len(line))])
					append(&tmp[i + 1], ..line[min(editor.cursor.x, cast(i32)len(line)):])
				}
				if i > editor.cursor.y + 1 {
					append(&tmp[i], ..editor.buffer[i - 1][:])
				}
			}
			editor.buffer = tmp
			return Refresh{}
		case:
			buffer.buffer_append_byte_at(
				&editor.buffer,
				u8(e.keyname),
				editor.cursor.y + 1,
				editor.cursor.x,
			)
			editor.cursor.x = saturating_add(editor.cursor.x, 1, editor.viewport.max_x)
			return Refresh{}
		}
	}
	return event
}

renderer :: proc(editor: Editor) {
	should_log := true
	//log.info("called renderer")
	todin.clear_screen()
	todin.reset_cursor()
	for i in 0 ..< editor.viewport.max_y + editor.viewport.scroll_amount {
		idx: i32 = saturating_add(
			i,
			editor.viewport.scroll_amount,
			cast(i32)len(editor.buffer) - 1,
		)
		line_len := min(cast(i32)len(editor.buffer[idx]), editor.viewport.max_x)
		for b in editor.buffer[idx][:line_len] {
			todin.print(rune(b))
		}
		if idx == cast(i32)len(editor.buffer) - 1 && should_log == true {
			should_log = false
			//	log.info("idx", idx, string(editor.buffer[idx][:]))
		}
		todin.move(i + 1, 0)
		if idx == cast(i32)len(editor.buffer) - 1 {
			break
		}
	}
	todin.move(editor.cursor.y + 1, editor.cursor.x)
	log.info(editor.cursor)
}
