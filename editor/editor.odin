package editor

import "../buffer"
import "../cursor"
import "../deps/ncurses/"
import "../viewport"
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
	viewport:     viewport.Viewport,
	buffer:       buffer.Buffer,
	event:        Event,
	mode:         Mode,
	current_file: string,
}

EditorEvent :: union {
	Event,
	ChangeRenderer,
}

renderer_run :: proc(renderer: ^Renderer(Editor)) {
	event: Event
	args_info: Args_Info
	init_keyboard_poll()
	parse_cli_arguments(&args_info)
	context.logger = set_file_logger(args_info.log_file)
	init_ncurses()
	renderer.data = renderer.init()
	log.info(args_info)
	current_time := time.now()
	loop: for {
		event = renderer.update(&renderer.data, poll_keypress())
		if time.duration_milliseconds(time.since(current_time)) >= 150 {
			current_time = time.now()
			ncurses.clear()
			ncurses.curs_set(0)
			ncurses.refresh()
			ncurses.move(0, 0)
			renderer.render(renderer.data)
			//ncurses_move(renderer.data.cur_x, renderer.data.cur_y)
			ncurses.curs_set(1)
			ncurses.refresh()
		}
		#partial switch e in event {
		case KeyboardEvent:
		case Quit:
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
