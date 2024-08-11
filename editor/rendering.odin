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
	//	editor.viewport.max_x, editor.viewport.max_y = getmaxxy()
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

handle_arrow_keys :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: todin.Event) {
	#partial switch e in editor_event {
	case:
		switch todin.key_to_string(e) {
		case "left":
			if editor.cursor.x > 0 {
				editor.cursor.x -= 1
				//event = events.UpdateCursorEvent{}
			}
		case "right":
			if editor.cursor.x < editor.viewport.max_x {
				editor.cursor.x += 1
				//event = events.UpdateCursorEvent{}
			}
		case "up":
			if editor.cursor.y > 0 {
				editor.cursor.y = saturating_sub(editor.cursor.y, 1)
				//event = events.UpdateCursorEvent{}
			}
			if editor.cursor.y >= 0 && editor.viewport.scroll_amount > 0 {
				log.info("scrolling up")
				editor.viewport.scroll_amount = saturating_sub(editor.viewport.scroll_amount, 1)
				//event = events.UpdateCursorEvent{}
			}
			log.info("cur_y:", editor.cursor.y, "scroll_y:", editor.viewport.scroll_amount)
		case "down":
			editor.cursor.y = saturating_add(editor.cursor.y, 1, editor.viewport.max_y)
			//event = events.UpdateCursorEvent{}
			if editor.cursor.y < editor.viewport.max_y {
				break
			}
			scroll_y := editor.viewport.scroll_amount + editor.viewport.max_y
			if scroll_y <= cast(i32)len(editor.buffer) {
				editor.viewport.scroll_amount = saturating_add(
					editor.viewport.scroll_amount,
					1,
					min(cast(i32)len(editor.buffer) - 1, scroll_y - 1),
				)
				//	event = events.UpdateCursorEvent{}
			} else {
				log.info("key_down: broke to outer loop:", scroll_y, editor.viewport.scroll_amount)
				break
			}
		}
	}
	return event
}

handle_normal_mode :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: todin.Event) {
	#partial switch e in editor_event {
	case:
		switch todin.key_to_string(e) {
		case "backspace":
			editor.cursor.x = saturating_sub(editor.cursor.x, 1)
			//event = events.UpdateCursorEvent{}
			if editor.cursor.x <= 0 && editor.cursor.y > 0 {
				editor.cursor.y = saturating_sub(editor.cursor.y, 1)
				editor.cursor.x = min(
					cast(i32)len(editor.buffer[editor.cursor.y]),
					editor.cursor.x,
				)
			}
		case "<c-s>":
			buffer.write_buffer_to_file(editor.buffer, editor.current_file)
			log.info("wrote to:", editor.current_file)
		case "I":
			editor.mode = .insert
		case "h":
			editor.cursor.x = saturating_sub(editor.cursor.x, 1)
		//event = events.UpdateCursorEvent{}
		case "k":
			editor.cursor.y = saturating_sub(editor.cursor.y, 1)
		//event = events.UpdateCursorEvent{}
		case "j":
			editor.cursor.y = saturating_add(editor.cursor.y, 1, editor.viewport.max_y)
		//event = events.UpdateCursorEvent{}
		case "l":
			editor.cursor.x = saturating_add(editor.cursor.x, 1, editor.viewport.max_x)
		//event = events.UpdateCursorEvent{}
		case "^":
			editor.cursor.x = 0
		//event = events.UpdateCursorEvent{}
		case "$":
			editor.cursor.x = cast(i32)len(editor.buffer[editor.cursor.y]) - 1
		//event = events.UpdateCursorEvent{}
		case "O":
			log.info("creating newline above is: unimplemented")
		case "o":
			log.info("creating newline below is: unimplemented")

		//event = events.UpdateCursorEvent{}
		}
	}
	return event
}

handle_insert_mode :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: todin.Event) {
	#partial switch e in editor_event {
	case todin.Key:
		switch todin.key_to_string(e) {
		case "backspace":
			if len(editor.buffer[editor.cursor.y]) > 0 && editor.cursor.x > 0 {
				delete_char(editor)
				editor.cursor.x = saturating_sub(editor.cursor.x, 1)
				event = todin.BackSpace{}
			}
		case "control+c":
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
				log.info(transmute(string)tmp[i][:])
			}
			editor.buffer = tmp
		case:
			buffer.buffer_append_byte_at(
				&editor.buffer,
				u8(e.keyname),
				editor.cursor.y,
				editor.cursor.x,
			)
			editor.cursor.x = saturating_add(editor.cursor.x, 1, editor.viewport.max_x)
			event = todin.Key{e.keyname, false}
		}
	case:
		event = e
	}
	return event
}

updater :: proc(editor: ^Editor, editor_event: todin.Event) -> (event: todin.Event) {
	#partial switch e in editor_event {
	case todin.Nothing:
		return todin.Nothing{}
	case todin.Key:
		switch todin.key_to_string(e) {
		case "<c-q>":
			return e
		}
	/*
		if e.key == "control+q" {
			event = events.Quit{}
		} else {
			switch (e.key) {
			case "KEY_RIGHT", "KEY_UP", "KEY_DOWN", "KEY_LEFT":
				event = handle_arrow_keys(editor, editor_event)
			case:
				switch editor.mode {
				case .normal:
					event = handle_normal_mode(editor, editor_event)
				case .insert:
					event = handle_insert_mode(editor, editor_event)
				}
			}
		}
	case events.Quit:
		event = events.Quit{}
    */
	}
	return event
}

renderer :: proc(editor: Editor) {
	should_log := true
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
			log.info("idx", idx, string(editor.buffer[idx][:]))
		}
		todin.move(i + 1, 0)
		if idx == cast(i32)len(editor.buffer) - 1 {
			break
		}
	}
}
