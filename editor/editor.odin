package editor

import "../buffer"
import "../cursor"
import "../deps/ncurses/"
import "../viewport"
import "./events"
import "core:bytes"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:os"

Mode :: enum {
	normal,
	insert,
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
			line_idx := buffer.get_line_index(editor.buffer, editor.viewport.cursor.cur_y)
			key_pos := line_idx + editor.viewport.cursor.cur_x - 1
			log.info("key_pos", key_pos)
			cursor.move_cursor_event(&editor.viewport.cursor, .left)
			buffer.buffer_remove_byte_at(&editor.buffer, key_pos)
		}
	case "I":
		if editor.mode == .normal {
			editor.mode = .insert
		}
	case:
		if editor.mode == .insert {
			if event.is_control == false {
				log.info(
					"cur_row",
					editor.viewport.cursor.cur_x,
					"cur_col",
					editor.viewport.cursor.cur_y,
				)
				line_idx := buffer.get_line_index(editor.buffer, editor.viewport.cursor.cur_y)
				key_pos := line_idx
				log.info("key_pos", key_pos)
				buffer.buffer_append_byte_at(&editor.buffer, event.key[0], key_pos)
				cursor.move_cursor_event(&editor.viewport.cursor, .right)
			}
		}
	}
	return editor
}

update :: proc(editor_state: ^Editor) -> (editor: ^Editor, event: Event) {
	editor_state.event = events.poll_keypress()
	editor = editor_state
	if editor_state.event.key != "" {
		editor = handle_keymap(editor_state, editor.event)
		event = UpdateMsg{}
		return editor, event
	}
	return editor_state, {}
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
	viewport.render(&editor.viewport, editor.buffer[:])
	ncurses.move(editor.viewport.cursor.cur_y, editor.viewport.cursor.cur_x)
	ncurses.refresh()
}

run :: proc(editor: ^Editor) {
	event: Event
	editor := editor
	for {
		editor, event = update(editor)
		switch _ in event {
		case UpdateMsg:
			log.info("rendering a frame")
			render(editor)
		}
	}
}
