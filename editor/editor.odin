package editor

import "../buffer"
import "../deps/todin"
import "core:log"
import "core:os"

Mode :: enum {
	normal,
	insert,
}

Cursor :: struct {
	y, x: i32,
}

Viewport :: struct {
	min_x, min_y, max_x, max_y, scroll_amount: i32,
}

Quit :: struct {}
Refresh :: struct {}

Event :: union {
	todin.Event,
	Quit,
	Refresh,
}

Editor :: struct {
	current_file: string,
	cursor:       Cursor,
	viewport:     Viewport,
	buffer:       buffer.Buffer,
	mode:         Mode,
}

run :: proc(editor: ^Editor) {
	args_info: Args_Info
	error := parse_cli_arguments(&args_info)
	switch error {
	case .parse_error, .open_file_error, .validation_error:
		os.exit(1)
	case .none, .help_request:
		break
	}
	context.logger = logger_init(args_info.log_file)
	todin.init()
	todin.enter_alternate_screen()
	editor^ = default_init()
	vp: Viewport = {
		max_x = editor.viewport.max_x,
		max_y = editor.viewport.max_y,
	}
	log.info(vp)
	log.info(args_info)
	tui_event: todin.Event
	renderer(editor^)
	loop: for {
		if !todin.poll() {
			continue
		}
		tui_event = todin.read()
		event := updater(editor, tui_event)
		switch e in event {
		case Quit:
			break loop
		case Refresh:
			renderer(editor^)
		case todin.Event:
			switch todin_event in e {
			case todin.Nothing:
				continue
			case todin.Key:
				log.info("key", todin_event.keyname)
			case todin.Resize:
			case todin.ArrowKey:
				log.info("arrow key:", e)
			case todin.EscapeKey:
			case todin.BackSpace:
			case todin.FunctionKey:
			}
		}
	}
	todin.leave_alternate_screen()
	todin.deinit()
}
