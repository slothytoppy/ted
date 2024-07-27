package editor

import "../buffer"
import "core:log"
import "core:strings"

Renderer :: struct($T: typeid) {
	data:   T,
	init:   proc() -> T,
	update: proc(model: ^T, event: Event) -> Event,
	render: proc(model: T) -> []string,
}

default_init :: proc() -> (editor: Editor) {
	init_ncurses()
	y, x := getmaxyx()
	editor.viewport.cursor = {
		max_x = x,
		max_y = y,
	}
	editor.viewport.max_y = y
	editor.viewport.max_x = x
	editor.viewport.scroll_y = 0
	init_keyboard_poll()
	cli_args: Args_Info
	parse_cli_arguments(&cli_args)
	editor.current_file = cli_args.file
	context.logger = set_file_logger(cli_args.log_file)
	if cli_args.file == "" {
		editor.buffer = make(buffer.Buffer, 1)
	} else {
		editor.buffer = load_buffer_from_file(cli_args.file)
	}
	return editor
}

default_updater :: proc(editor: ^Editor, editor_event: Event) -> (event: Event) {
	switch e in editor_event {
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
