package editor

import "../buffer"
import "../viewport"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:os"

Nothing :: struct {}
Quit :: struct {}
GoToLineStart :: struct {}
GoToLineEnd :: struct {}
Scroll :: struct {
	Direction: enum {
		up,
		down,
	},
	amount:    i32,
}

Event :: union {
	Nothing,
	KeyboardEvent,
	Quit,
	GoToLineStart,
	GoToLineEnd,
	Scroll,
}

Renderer :: struct($T: typeid) {
	data:   T,
	init:   proc() -> T,
	update: proc(model: ^T, event: Event) -> Event,
	render: proc(model: T) -> []string,
}

ChangeRenderer :: proc(
	$T: typeid,
	init: proc() -> T,
	update: proc(t: ^T, event: Event) -> Event,
	render: proc(t: T) -> []string,
)

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

default_updater :: proc(editor: ^Editor, editor_event: Event) -> (event: Event) {
	switch e in editor_event {
	case Scroll:
		break
	case Nothing:
		return Nothing{}
	case KeyboardEvent:
		if e.key == "control+q" {
			event = Quit{}
		} else {
			switch (e.key) {
			case "KEY_LEFT":
				if editor.viewport.cur_x == 0 {
					break
				}
				editor.viewport.cur_x -= 1
			case "KEY_RIGHT":
				if editor.viewport.cur_x >= editor.viewport.max_x {
					break
				}
				editor.viewport.cur_x += 1
			case "KEY_UP":
				if editor.viewport.cur_y == 0 {
					editor.viewport.scroll_y -= 1
					break
				}
				editor.viewport.cur_y -= 1
				log.info(editor.viewport.cur_y, editor.viewport.scroll_y)
			case "KEY_DOWN":
				if editor.viewport.cur_y >= editor.viewport.max_y {
					editor.viewport.scroll_y += 1
					log.info(editor.viewport.cur_y, editor.viewport.scroll_y)
					break
				}
				editor.viewport.cur_y += 1
			}
			event = editor_event
		}
	case Quit:
		event = Quit{}
	case GoToLineStart:
		unimplemented()
	case GoToLineEnd:
		unimplemented()
	}
	return event
}

// TODO: fix scrolling
default_renderer :: proc(editor: Editor) -> []string {
	cur_y := editor.viewport.cur_y
	ncurses_move(cur_y + editor.viewport.scroll_y, 0)
	max_y := editor.viewport.scroll_y + editor.viewport.max_y
	for line, i in editor.buffer {
		i := cast(i32)i
		if i >= editor.viewport.max_y + editor.viewport.scroll_y {
			break
		}
		ncurses_mvprint(
			i,
			0,
			format_to_cstring(
				transmute(string)editor.buffer[clamp(i + editor.viewport.scroll_y, 0, max_y)][:],
			),
		)
	}
	return {}
}
