package editor

import "../buffer"
import "core:flags"
import "core:log"
import "core:os"
import "core:strings"

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
	init_ncurses()
	y, x := getmaxyx()
	editor.viewport.cursor = {
		max_x = x,
		max_y = y,
	}
	editor.viewport.max_y = y
	editor.viewport.max_x = x
	editor.viewport.scroll_y = 0
	editor.current_file = cli_args.file
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

default_renderer :: proc(editor: Editor) -> []string {
	log.info("called renderer")
	strs := make([]string, len(editor.buffer))
	for line, i in editor.buffer {
		strs[i] = transmute(string)line[:]
	}
	return strs
}
