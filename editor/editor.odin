package editor

import "../buffer"
import "../cursor"
import "../deps/ncurses/"
import "../file_viewer"
import "../viewport"
import "core:fmt"
import "core:log"
import "core:os"

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
	file_viewer:  file_viewer.FileViewer,
}

ChangeRenderer :: proc(
	$T: typeid,
	init: proc() -> T,
	update: proc(t: ^T, event: Event) -> Event,
	render: proc(t: T) -> []string,
)

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
	renderer.init()
	log.info(args_info)
	loop: for {
		event = renderer.update(&renderer.data, poll_keypress())
		#partial switch e in event {
		case KeyboardEvent:
			ncurses.clear()
			ncurses.refresh()
			ncurses.move(0, 0)
			max_x := getmaxx()
			max_y := getmaxy()
			str := renderer.render(renderer.data)
			for s, i in str {
				if cast(i32)i > max_y {
					break
				}
				ncurses.printw("%s", fmt.ctprint(s))
				ncurses.move(cast(i32)i + 1, 0)
			}
			ncurses.refresh()
		case Quit:
			break loop
		}
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
