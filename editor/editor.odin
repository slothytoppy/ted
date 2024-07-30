package editor

import "../buffer"
import "../deps/ncurses/"
import "../viewport"
import "./events"
import "core:log"
import "core:os"

Mode :: enum {
	normal,
	insert,
}

Editor :: struct {
	current_file: string,
	viewport:     viewport.Viewport,
	buffer:       buffer.Buffer,
	mode:         Mode,
}

run :: proc(renderer: ^events.Renderer($T)) {
	event: events.Event
	args_info: Args_Info
	events.init_keyboard_poll()
	error := parse_cli_arguments(&args_info)
	switch error {
	case .parse_error, .open_file_error, .validation_error:
		os.exit(1)
	case .none, .help_request:
		break
	}
	context.logger = logger_init(args_info.log_file)
	_ = init_ncurses()
	renderer.data = renderer.init()
	/*
	ncurses.clear()
	ncurses.curs_set(0)
	ncurses.refresh()
	ncurses.move(0, 0)
	renderer.render(renderer.data)
	ncurses.curs_set(1)
	move(renderer.data.viewport.cur_y, renderer.data.viewport.cur_x)
	ncurses.refresh()
  */
	log.info(args_info)
	loop: for {
		event = renderer.update(&renderer.data, events.poll_keypress())
		#partial switch e in event {
		case events.KeyboardEvent, events.UpdateCursorEvent:
			ncurses.clear()
			ncurses.curs_set(0)
			ncurses.move(0, 0)
			renderer.render(renderer.data)
			move(renderer.data.viewport.cur_y, renderer.data.viewport.cur_x)
			ncurses.curs_set(1)
			ncurses.refresh()
		case events.Quit:
			break loop
		}
		free_all(context.temp_allocator)
	}
	ncurses.endwin()
}
