package editor

import "../cursor"
import "../deps/ncurses/"
import "../viewport"
import "./events"
import "core:log"
import "core:os"

Buffer :: #type [dynamic]byte

Editor :: struct {
	pos:      cursor.Cursor,
	viewport: viewport.Viewport,
	buffer:   Buffer,
	keymap:   events.Keymap,
}

init_editor :: proc() -> Editor {
	ncurses.initscr()
	ncurses.noecho()
	ncurses.raw()
	ncurses.keypad(ncurses.stdscr, true)
	return {}
}

// maybe just calling endwin is fine here?
deinit_editor :: proc() {
	ncurses.echo()
	ncurses.noraw()
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

handle_keymap :: proc(ed: ^Editor, event: events.Event) {
	val, ok := ed.keymap[event.key]
	if event.key == "KEY_UP" {
		cursor.move_cursor_event(&ed.pos, .up)
	} else if event.key == "KEY_DOWN" {
		cursor.move_cursor_event(&ed.pos, .down)
	} else if event.key == "KEY_LEFT" {
		cursor.move_cursor_event(&ed.pos, .left)
	} else if event.key == "KEY_RIGHT" {
		cursor.move_cursor_event(&ed.pos, .right)
	}
}

@(private)
check_vec4_collision :: proc(vec4: [4]i32) -> bool {
	if vec4.x > vec4.w || vec4.y > vec4.z {
		return true
	}
	return false
}

/* 
   for things to be called everytime the editor needs to rerender,
 */
render :: proc(ed: Editor) {
	ed := ed
	viewport.render(ed.viewport)
	ncurses.move(ed.pos.cur_y, ed.pos.cur_x)
	ncurses.refresh()
}
