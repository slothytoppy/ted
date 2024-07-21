package editor

import "../cursor"
import "../deps/ncurses/"
import "../viewport"
import "./events"
import "core:bytes"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:os"

Buffer :: #type [dynamic]byte

Mode :: enum {
	normal,
	insert,
	file_viewer,
}

Editor :: struct {
	pos:      cursor.Cursor,
	viewport: viewport.Viewport,
	buffer:   Buffer,
	keymap:   events.Keymap,
	mode:     Mode,
}

init_editor :: proc() -> Editor {
	ncurses.initscr()
	ncurses.noecho()
	ncurses.raw()
	ncurses.keypad(ncurses.stdscr, true)
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	return {pos = {max_x = x, max_y = y}}
}

// calling just endwin seems to be fine
deinit_editor :: proc() {
	ncurses.endwin()
}

load_buffer_from_file :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file_from_filename(file)
	if err != true {
		return {}
	}
	append(&buffer, ..data[:])
	return buffer
}

buffer_append_byte_at :: proc(buffer: ^Buffer, b: byte, #any_int pos: int) {
	inject_at(buffer, pos, b)
}

buffer_assign_byte_at :: proc(buffer: ^Buffer, b: byte, #any_int pos: int) {
	assign_at(buffer, pos, b)
}

// puts a space at position: pos in the buffer, doesnt grow or shrink the dynamic array
buffer_remove_byte_at :: proc(buffer: ^Buffer, #any_int pos: int) {
	assign_at(buffer, pos, ' ')
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

handle_keymap :: proc(editor: ^Editor, event: events.Event) {
	switch event.key {
	case "KEY_UP":
		cursor.move_cursor_event(&editor.pos, .up)
	case "KEY_DOWN":
		cursor.move_cursor_event(&editor.pos, .down)
	case "KEY_LEFT":
		cursor.move_cursor_event(&editor.pos, .left)
	case "KEY_RIGHT":
		cursor.move_cursor_event(&editor.pos, .right)
	case "control+q":
		deinit_editor()
		os.exit(0)
	}
}

/* 
for things to be called everytime the editor needs to rerender,
 */
render :: proc(editor: ^Editor, event: events.Event) {
	command: viewport.Command
	if editor.pos.cur_y == 0 && event.key == "KEY_UP" {
		command = .up
	} else if editor.pos.cur_y == editor.pos.max_y && event.key == "KEY_DOWN" {
		command = .down
	}
	viewport.render(&editor.viewport, editor.buffer[:], command)
	ncurses.move(editor.pos.cur_y, editor.pos.cur_x)
	ncurses.refresh()
}
