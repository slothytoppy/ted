package editor

import "../buffer"
import "../file_viewer"
import "../viewport"
import "./events"
import "core:flags"
import "core:fmt"
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
	editor.viewport.max_x, editor.viewport.max_y = getmaxxy()
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

handle_arrow_keys :: proc(editor: ^Editor, editor_event: events.Event) -> (event: events.Event) {
	#partial switch e in editor_event {
	case events.KeyboardEvent:
		switch e.key {
		case "KEY_LEFT":
			if editor.viewport.cur_x > 0 {
				editor.viewport.cur_x -= 1
				event = events.UpdateCursorEvent{}
			}
		case "KEY_RIGHT":
			if editor.viewport.cur_x < editor.viewport.max_x {
				editor.viewport.cur_x += 1
				event = events.UpdateCursorEvent{}
			}
		case "KEY_UP":
			if editor.viewport.cur_y >= 0 {
				if editor.viewport.scroll_y > 0 && editor.viewport.cur_y == 0 {
					editor.viewport.scroll_y -= 1
					event = events.UpdateCursorEvent{}
				} else {
					editor.viewport.cur_y -= 1
					event = events.UpdateCursorEvent{}
				}
			}
			log.info("cur_y:", editor.viewport.cur_y, "scroll_y:", editor.viewport.scroll_y)
		case "KEY_DOWN":
			if editor.viewport.cur_y < editor.viewport.max_y {
				editor.viewport.cur_y += 1
				event = events.UpdateCursorEvent{}
			} else {
				if editor.viewport.scroll_y + editor.viewport.cur_y < cast(i32)len(editor.buffer) {
					editor.viewport.scroll_y += 1
					event = events.UpdateCursorEvent{}
				}
			}
		}
	}
	return event
}

handle_normal_mode :: proc(editor: ^Editor, editor_event: events.Event) -> (event: events.Event) {
	#partial switch e in editor_event {
	case events.KeyboardEvent:
		switch e.key {
		case "control+s":
			buffer.write_buffer_to_file(editor.buffer, editor.current_file)
			log.info("wrote to:", editor.current_file)
		case "I":
			editor.mode = .insert
		case "h":
			if editor.viewport.cur_x > 0 {
				editor.viewport.cur_x -= 1
				event = events.UpdateCursorEvent{}
			}
		case "k":
			if editor.viewport.cur_y > 0 {
				editor.viewport.cur_y -= 1
				event = events.UpdateCursorEvent{}
			}
		case "j":
			if editor.viewport.cur_y < editor.viewport.max_y {
				editor.viewport.cur_y += 1
				event = events.UpdateCursorEvent{}
			}
		case "l":
			if editor.viewport.cur_x < editor.viewport.max_x {
				editor.viewport.cur_x += 1
				event = events.UpdateCursorEvent{}
			}
		case "^":
			editor.viewport.cur_x = 0
			event = events.UpdateCursorEvent{}
		case "$":
			editor.viewport.cur_x = cast(i32)len(editor.buffer[editor.viewport.cur_y]) - 1
			event = events.UpdateCursorEvent{}
		case "O":
			log.info("creating newline above is: unimplemented")
		case "o":
			log.info("creating newline below is: unimplemented")
		}
	}
	return event
}

handle_insert_mode :: proc(editor: ^Editor, editor_event: events.Event) -> (event: events.Event) {
	#partial switch e in editor_event {
	case events.KeyboardEvent:
		switch e.key {
		case "KEY_BACKSPACE":
			if len(editor.buffer[editor.viewport.cur_y]) > 0 && editor.viewport.cur_x > 0 {
				delete_char(editor)
				editor.viewport.cur_x -= 1
				event = events.UpdateCursorEvent{}
			}
		case "control+c":
			editor.mode = .normal
		case:
			if e.key == "enter" {
				tmp := make(buffer.Buffer, len(editor.buffer) + 1)
				for line, i in editor.buffer {
					i := cast(i32)i
					if i < editor.viewport.cur_y || i > editor.viewport.cur_y + 1 {
						append(&tmp[i], ..line[:])
					} else if i == editor.viewport.cur_y {
						append(&tmp[i], ..line[:min(editor.viewport.cur_x, cast(i32)len(line))])
						append(
							&tmp[i + 1],
							..line[min(editor.viewport.cur_x, cast(i32)len(line)):],
						)
					}
					log.info(transmute(string)tmp[i][:])
				}
				editor.buffer = tmp
			} else {
				buffer.buffer_append_byte_at(
					&editor.buffer,
					e.key[0],
					editor.viewport.cur_y,
					editor.viewport.cur_x,
				)
				editor.viewport.cur_x += 1
				event = events.UpdateCursorEvent{}
			}
		}
	}
	return event
}

default_updater :: proc(editor: ^Editor, editor_event: events.Event) -> (event: events.Event) {
	switch e in editor_event {
	case events.UpdateCursorEvent:
		refresh_screen()
	case events.Enter:
	case events.Nothing:
		return events.Nothing{}
	case events.KeyboardEvent:
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
			//	event = editor_event
		}
	case events.Quit:
		event = events.Quit{}
	}
	return event
}

// TODO: fix scrolling
default_renderer :: proc(editor: Editor) -> []string {
	cur_y := editor.viewport.cur_y
	//move(cur_y + editor.viewport.scroll_y, 0)
	max_y := editor.viewport.scroll_y + editor.viewport.max_y
	for line, i in editor.buffer {
		i := cast(i32)i
		if i + editor.viewport.scroll_y >= max_y {
			break
		}
		for b, row in line {
			if cast(i32)row > editor.viewport.max_x {
				break
			}
			if b == '\n' {
				i += 1
			}
			print(format_to_cstring(cast(rune)b))
		}
		move(i + 1, 0)
		/*
		mvprint(
			i,
			0,
			format_to_cstring(
				transmute(string)editor.buffer[min(i + editor.viewport.scroll_y, max_y, cast(i32)len(editor.buffer))][:],
			),
		)
      */
	}
	return {}
}
