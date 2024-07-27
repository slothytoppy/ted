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
	keymap:       Keymap,
	event:        Event,
	mode:         Mode,
	current_file: string,
	file_viewer:  file_viewer.FileViewer,
}

init_editor :: proc() -> Editor {
	ncurses.initscr()
	ncurses.noecho()
	ncurses.raw()
	ncurses.keypad(ncurses.stdscr, true)
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	editor: Editor
	editor.viewport.cursor = {
		max_x = x,
		max_y = y,
	}
	editor.viewport.max_y = y
	editor.viewport.max_x = x
	editor.viewport.scroll_y = 0
	init_keyboard_poll()
	editor.keymap = init_keymap(
		"KEY_UP",
		"KEY_DOWN",
		"KEY_LEFT",
		"KEY_RIGHT",
		"control+c",
		"control+q",
		"shift+a",
		"KEY_ENTER",
		"o",
		"O",
		"^",
		"$",
		"control+s",
	)
	assert(editor.keymap != nil)
	cli_args: Args_Info
	parse_cli_arguments(&cli_args)
	editor.current_file = cli_args.file
	context.logger = set_file_logger(cli_args.log_file)
	if cli_args.file == "" {
		editor.buffer = make(buffer.Buffer, 1)
	} else {
		editor.buffer = load_buffer_from_file(cli_args.file)
	}
	log.info(editor.mode)
	return editor
}

load_buffer_from_file :: proc(file: string) -> buffer.Buffer {
	return buffer.load_buffer_from_file(file)
}

// just calling endwin seems to be fine
deinit_editor :: proc() {
	ncurses.endwin()
}

default_key_maps :: proc() -> Keymap {
	return init_keymap(
		"KEY_UP",
		"KEY_DOWN",
		"KEY_LEFT",
		"KEY_RIGHT",
		"control+c",
		"control+q",
		"shift+a",
		"-",
	)
}

handle_keymap :: proc(editor: ^Editor) {
	switch editor.event.(KeyboardEvent).key {
	case "KEY_UP":
		cursor.move_cursor_event(&editor.viewport.cursor, .up)
	case "KEY_DOWN":
		cursor.move_cursor_event(&editor.viewport.cursor, .down)
	case "KEY_LEFT":
		cursor.move_cursor_event(&editor.viewport.cursor, .left)
	case "KEY_RIGHT":
		cursor.move_cursor_event(&editor.viewport.cursor, .right)
	case "control+q":
		deinit_editor()
		os.exit(0)
	case "control+c":
		if editor.mode == .insert {
			editor.mode = .normal
		}
	case "KEY_BACKSPACE":
		if editor.mode == .insert {
			cursor.move_cursor_event(&editor.viewport.cursor, .left)
			buffer.buffer_remove_byte_at(
				&editor.buffer,
				editor.viewport.cursor.cur_y,
				editor.viewport.cursor.cur_x,
			)
		}
	case "enter":
		if editor.mode == .insert {
			inject_at(
				&editor.buffer[editor.viewport.cursor.cur_y],
				cast(int)editor.viewport.cursor.cur_x,
				'\n',
			)
		}
		cursor.move_cursor_event(&editor.viewport.cursor, .down)
	case "i":
		if editor.mode == .normal {
			editor.mode = .insert
		}
	case "^":
		goto_line_start(&editor.viewport)
	case "$":
		goto_line_end(&editor.viewport, len(editor.buffer[editor.viewport.cursor.cur_y]))
	case "control+s":
		log.info("control+s")
		result := buffer.write_buffer_to_file(editor.buffer, editor.current_file)
		if result == false {
			log.info("failed to write to file:", editor.current_file)
		}
	case:
		if editor.mode == .insert {
			if editor.event.(KeyboardEvent).is_control == false {
				log.info(
					"cur_row",
					editor.viewport.cursor.cur_x,
					"cur_col",
					editor.viewport.cursor.cur_y,
				)
				buffer.buffer_append_bytes_at(
					&editor.buffer,
					line = editor.viewport.cursor.cur_y,
					offset = editor.viewport.cursor.cur_x,
					bytes = transmute([]byte)editor.event.(KeyboardEvent).key[:],
				)
				cursor.move_cursor_event(&editor.viewport.cursor, .right)
			}
		}
	}
}

update :: proc(editor_state: ^Editor) -> bool {
	editor_state := editor_state
	editor_state.event = poll_keypress()
	log.info(editor_state.mode)
	if editor_state.event.(KeyboardEvent).key != "" {
		handle_keymap(editor_state)
		return true
	}
	return false
}

renderer_run :: proc(renderer: ^Renderer(Editor)) {
	renderer.data = init_editor()
	event := Event{}
	loop: for {
		get_input := poll_keypress()
		if get_input != {} {
			event = get_input
		}
		event = renderer.update(&renderer.data, event)
		#partial switch e in event {
		case KeyboardEvent:
			log.info(renderer.data.buffer)
			ncurses.clear()
			ncurses.refresh()
			ncurses.move(0, 0)
			max_x := ncurses.getmaxx(ncurses.stdscr)
			max_y := ncurses.getmaxy(ncurses.stdscr)
			str := renderer.render(renderer.data)
			log.info(str)
			line := max_x / max(0, cast(i32)len(str), 1)
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
}

/* 
for things to be called everytime the editor needs to rerender,
 */
render :: proc(editor: ^Editor) {
	viewport.render(&editor.viewport, editor.buffer)
	log.debug("moving to", editor.viewport.cursor.cur_x, editor.viewport.cursor.cur_y)
	ncurses.move(editor.viewport.cursor.cur_y, editor.viewport.cursor.cur_x)
	ncurses.refresh()
}

run :: proc() {
	editor := init_editor()

	render(&editor)
	event: bool
	for {
		event = update(&editor)
		if event == true {
			log.info(editor.event.(KeyboardEvent).key)
			log.info("rendering a frame")
			render(&editor)
		}
	}

	deinit_editor()
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
