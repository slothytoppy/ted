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
		editor.buffer = load_buffer_from_file(cli_args.file)
	}
	return editor
}

default_updater :: proc(editor: ^Editor, editor_event: events.Event) -> (event: events.Event) {
	switch e in editor_event {
	case events.Enter:
	case events.Nothing:
		return events.Nothing{}
	case events.KeyboardEvent:
		if e.key == "control+q" {
			event = events.Quit{}
		} else {
			switch (e.key) {
			case "KEY_LEFT":
				if editor.viewport.cur_x <= 0 {
					break
				}
				editor.viewport.cur_x -= 1
			case "KEY_RIGHT":
				if editor.viewport.cur_x >= editor.viewport.max_x {
					break
				}
				editor.viewport.cur_x += 1
			case "KEY_UP":
				if editor.viewport.cur_y > 0 {
					if editor.viewport.scroll_y > 0 {
						editor.viewport.scroll_y -= 1
					} else {
						editor.viewport.cur_y -= 1
					}
				}
				log.info(editor.viewport.cur_y, editor.viewport.scroll_y)
			case "KEY_DOWN":
				if editor.viewport.cur_y < editor.viewport.max_y {
					editor.viewport.cur_y += 1
				} else {
					if editor.viewport.scroll_y + editor.viewport.cur_y <
					   cast(i32)len(editor.buffer) {
						editor.viewport.scroll_y += 1
					}
				}
			case:
				if editor.mode == .normal {
					switch e.key {
					case "I":
						editor.mode = .insert
					case "h":
						editor.viewport.cur_x -= 1
					case "k":
						editor.viewport.cur_y -= 1
					case "j":
						editor.viewport.cur_y += 1
					case "l":
						editor.viewport.cur_x += 1
					case "^":
						editor.viewport.cur_x = 0
					case "$":
						editor.viewport.cur_x = cast(i32)len(editor.buffer[editor.viewport.cur_y])
					case "O":
						log.info("creating newline above is: unimplemented")
					case "o":
						log.info("creating newline belowis: unimplemented")
					}
				} else {
					switch e.key {
					case "KEY_BACKSPACE":
						buffer.buffer_remove_byte_at(
							&editor.buffer,
							editor.viewport.cur_y,
							editor.viewport.cur_x - 1,
						)
						editor.viewport.cur_x -= 1
					case "control+c":
						editor.mode = .normal
					case:
						buffer.buffer_append_byte_at(
							&editor.buffer,
							e.key[0],
							editor.viewport.cur_y,
							editor.viewport.cur_x,
						)
						editor.viewport.cur_x += 1
					}
				}
			}
			event = editor_event
		}
	case events.Quit:
		event = events.Quit{}
	case events.GoToLineStart:
		unimplemented()
	case events.GoToLineEnd:
		unimplemented()
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
		mvprint(
			i,
			0,
			format_to_cstring(
				transmute(string)editor.buffer[min(i + editor.viewport.scroll_y, max_y, cast(i32)len(editor.buffer))][:],
			),
		)
	}
	return {}
}
