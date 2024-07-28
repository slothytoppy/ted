package editor

import "../buffer"
import "../cursor"
import "../deps/ncurses/"
import "../file_viewer"
import "../viewport"
import "./events"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:time"

Mode :: enum {
	normal,
	insert,
}

Editor :: struct {
	viewport: viewport.Viewport,
	buffer:   buffer.Buffer,
	mode:     Mode,
}

renderer_run :: proc(renderer: ^events.Renderer($T)) {
	event: events.Event
	args_info: Args_Info
	events.init_keyboard_poll()
	parse_cli_arguments(&args_info)
	context.logger = set_file_logger(args_info.log_file)
	init_ncurses()
	if args_info.file == "" {
		//
	}
	renderer.data = renderer.init()
	log.info(args_info)
	loop: for {
		event = renderer.update(&renderer.data, events.poll_keypress())
		#partial switch e in event {
		case events.KeyboardEvent:
			if e.key == "KEY_UP" ||
			   e.key == "KEY_DOWN" ||
			   e.key == "KEY_LEFT" ||
			   e.key == "KEY_RIGHT" ||
			   renderer.data.mode == .insert {
				ncurses.clear()
				ncurses.curs_set(0)
				ncurses.refresh()
				ncurses.move(0, 0)
				renderer.render(renderer.data)
				move(renderer.data.viewport.cur_y, renderer.data.viewport.cur_x)
				ncurses.curs_set(1)
				ncurses.refresh()
			}
		case events.Quit:
			break loop
		}
		free_all(context.temp_allocator)
	}
	ncurses.endwin()
}

set_file_logger :: proc(handle: os.Handle) -> log.Logger {
	fd := handle
	if handle == 0 {
		fd, _ = os.open("/dev/null") // makes it so that if the log file is not given it does not write to stdin and logs go nowhere
	}
	return log.create_file_logger(fd)
}

goto_line_start :: proc(vp: ^viewport.Viewport) {
	log.info("line start")
	vp.cursor.cur_x = 0
}

goto_line_end :: proc(vp: ^viewport.Viewport, #any_int line_length: i32) {
	current_line := vp.cursor.cur_y
	log.info("line len:", line_length)
	cursor.move_cursor_to(&vp.cursor, current_line, line_length - 1)
}
