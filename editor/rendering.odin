package editor

import "../buffer"
import "./events"
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
			if editor.viewport.cur_y > 0 {
				editor.viewport.cur_y = saturating_sub(editor.viewport.cur_y, 1)
				event = events.UpdateCursorEvent{}
			}
			if editor.viewport.cur_y >= 0 && editor.viewport.scroll_y > 0 {
				log.info("scrolling up")
				editor.viewport.scroll_y = saturating_sub(editor.viewport.scroll_y, 1)
				event = events.UpdateCursorEvent{}
			}
			log.info("cur_y:", editor.viewport.cur_y, "scroll_y:", editor.viewport.scroll_y)
		case "KEY_DOWN":
			editor.viewport.cur_y = saturating_add(editor.viewport.cur_y, 1, editor.viewport.max_y)
			event = events.UpdateCursorEvent{}
			if editor.viewport.cur_y < editor.viewport.max_y {
				break
			}
			scroll_y := editor.viewport.scroll_y + editor.viewport.max_y
			if scroll_y <= cast(i32)len(editor.buffer) {
				editor.viewport.scroll_y = saturating_add(
					editor.viewport.scroll_y,
					1,
					min(cast(i32)len(editor.buffer) - 1, scroll_y - 1),
				)
				event = events.UpdateCursorEvent{}
			} else {
				log.info("key_down: broke to outer loop:", scroll_y, editor.viewport.scroll_y)
				break
			}
		}
	}
	return event
}

handle_normal_mode :: proc(editor: ^Editor, editor_event: events.Event) -> (event: events.Event) {
	#partial switch e in editor_event {
	case events.KeyboardEvent:
		switch e.key {
		case "backspace":
			editor.viewport.cur_x = saturating_sub(editor.viewport.cur_x, 1)
			event = events.UpdateCursorEvent{}
			if editor.viewport.cur_x <= 0 && editor.viewport.cur_y > 0 {
				editor.viewport.cur_y = saturating_sub(editor.viewport.cur_y, 1)
				editor.viewport.cur_x = min(
					cast(i32)len(editor.buffer[editor.viewport.cur_y]),
					editor.viewport.max_x,
				)
			}
			event = events.UpdateCursorEvent{}
		case "control+s":
			buffer.write_buffer_to_file(editor.buffer, editor.current_file)
			log.info("wrote to:", editor.current_file)
		case "I":
			editor.mode = .insert
		case "h":
			editor.viewport.cur_x = saturating_sub(editor.viewport.cur_x, 1)
			event = events.UpdateCursorEvent{}
		case "k":
			editor.viewport.cur_y = saturating_sub(editor.viewport.cur_y, 1)
			event = events.UpdateCursorEvent{}
		case "j":
			editor.viewport.cur_y = saturating_add(editor.viewport.cur_y, 1, editor.viewport.max_y)
			event = events.UpdateCursorEvent{}
		case "l":
			editor.viewport.cur_x = saturating_add(editor.viewport.cur_x, 1, editor.viewport.max_x)
			event = events.UpdateCursorEvent{}
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
		case "backspace":
			if len(editor.buffer[editor.viewport.cur_y]) > 0 && editor.viewport.cur_x > 0 {
				delete_char(editor)
				editor.viewport.cur_x = saturating_sub(editor.viewport.cur_x, 1)
				event = events.UpdateCursorEvent{}
			}
		case "control+c":
			editor.mode = .normal
		case "enter":
			tmp := make(buffer.Buffer, len(editor.buffer) + 1)
			for line, i in editor.buffer {
				i := cast(i32)i
				if i < editor.viewport.cur_y {
					append(&tmp[i], ..line[:])
				} else if i == editor.viewport.cur_y {
					append(&tmp[i], ..line[:min(editor.viewport.cur_x, cast(i32)len(line))])
					append(&tmp[i + 1], ..line[min(editor.viewport.cur_x, cast(i32)len(line)):])
				}
				if i > editor.viewport.cur_y + 1 {
					append(&tmp[i], ..editor.buffer[i - 1][:])
				}
				log.info(transmute(string)tmp[i][:])
			}
			editor.buffer = tmp
		case:
			buffer.buffer_append_byte_at(
				&editor.buffer,
				e.key[0],
				editor.viewport.cur_y,
				editor.viewport.cur_x,
			)
			editor.viewport.cur_x = saturating_add(editor.viewport.cur_x, 1, editor.viewport.max_x)
			event = events.UpdateCursorEvent{}
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
		}
	case events.Quit:
		event = events.Quit{}
	}
	return event
}

default_renderer :: proc(editor: Editor) {
	should_log := true
	for i in 0 ..< editor.viewport.max_y + editor.viewport.scroll_y {
		idx: i32 = saturating_add(i, editor.viewport.scroll_y, cast(i32)len(editor.buffer) - 1)
		line_len := min(cast(i32)len(editor.buffer[idx]), editor.viewport.max_x)
		for b in editor.buffer[idx][:line_len] {
			print(format_to_cstring(rune(b)))
		}
		if idx == cast(i32)len(editor.buffer) - 1 && should_log == true {
			should_log = false
			log.info("idx", idx, string(editor.buffer[idx][:]))
		}
		move(i + 1, 0)
		if idx == cast(i32)len(editor.buffer) - 1 {
			break
		}
	}
}
