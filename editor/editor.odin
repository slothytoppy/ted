package editor

import "../buffer"
import "../cursor"
import "../deps/ncurses/"
import "../viewport"
import "./events"
import "core:log"
import "core:os"

Mode :: enum {
	normal,
	insert,
	file_viewer,
}

UpdateMsg :: struct {}

Event :: union {
	UpdateMsg,
}

Editor :: struct {
	viewport: viewport.Viewport,
	buffer:   buffer.Buffer,
	keymap:   events.Keymap,
	event:    events.KeyboardEvent,
	mode:     Mode,
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
	return editor
}

load_buffer_from_file :: proc(file: string) -> buffer.Buffer {
	return buffer.load_buffer_from_file(file)
}

// just calling endwin seems to be fine
deinit_editor :: proc() {
	ncurses.endwin()
}

default_key_maps :: proc() -> events.Keymap {
	return events.init_keymap(
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

handle_keymap :: proc(editor: ^Editor, event: events.KeyboardEvent) -> ^Editor {
	switch event.key {
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
	case "KEY_BACKSPACE":
		if editor.mode == .insert {
			cursor.move_cursor_event(&editor.viewport.cursor, .left)
			buffer.buffer_remove_byte_at(
				&editor.buffer,
				editor.viewport.cursor.cur_y,
				editor.viewport.cursor.cur_x,
			)
		}
	case "KEY_ENTER", "control+j":
		inject_at(
			&editor.buffer[editor.viewport.cursor.cur_y],
			cast(int)editor.viewport.cursor.cur_x,
			'\n',
		)
		cursor.move_cursor_event(&editor.viewport.cursor, .down)
	case "F":
		if editor.mode != .file_viewer {
			editor.mode = .file_viewer
		} else {
			editor.mode = .normal
		}
	case "I":
		if editor.mode == .normal {
			editor.mode = .insert
		}
	case:
		log.info("key=", event.key)
		if editor.mode == .insert {
			if event.is_control == false {
				log.info(
					"cur_row",
					editor.viewport.cursor.cur_x,
					"cur_col",
					editor.viewport.cursor.cur_y,
				)
				buffer.buffer_append_byte_at(
					&editor.buffer,
					event.key[0],
					editor.viewport.cursor.cur_y,
					editor.viewport.cursor.cur_x,
				)
				cursor.move_cursor_event(&editor.viewport.cursor, .right)
			}
		}
	}
	return editor
}

update :: proc(editor_state: ^Editor) -> (editor: Editor, event: Event) {
	editor_state.event = events.poll_keypress()
	editor = editor_state^
	if editor_state.event.key != "" {
		editor = handle_keymap(editor_state, editor.event)^
		event = UpdateMsg{}
		return editor, event
	}
	return editor_state^, {}
}

/* 
for things to be called everytime the editor needs to rerender,
 */
render :: proc(editor: ^Editor) {
	command: viewport.Command
	if editor.event.key == "KEY_UP" {
		command = .up
	} else if editor.event.key == "KEY_DOWN" {
		command = .down
	}
	viewport.render(&editor.viewport, editor.buffer)
	ncurses.move(editor.viewport.cursor.cur_y, editor.viewport.cursor.cur_x)
	ncurses.refresh()
}

run :: proc() {
	cli_args: Args_Info
	parse_cli_arguments(&cli_args)
	editor := init_editor()
	events.init_keyboard_poll()
	editor.keymap = events.init_keymap(
		"KEY_UP",
		"KEY_DOWN",
		"KEY_LEFT",
		"KEY_RIGHT",
		"control+c",
		"control+q",
		"shift+a",
		"KEY_ENTER",
	)
	assert(editor.keymap != nil)
	context.logger = set_file_logger(cli_args.log_file)
	if cli_args.file == "" {
		editor.mode = .file_viewer
	} else {
		editor.buffer = load_buffer_from_file(cli_args.file)
	}
	event: Event
	render(&editor)
	for {
		editor, event = update(&editor)
		switch _ in event {
		case UpdateMsg:
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
