package editor

import "../cursor"
import ncurses "../deps/ncurses/"
import "../viewport"
import "core:log"
import "core:strings"

Mode :: enum {
	normal,
	insert,
}

Editor_State :: struct {
	buffer:  Buffer,
	mode:    Mode,
	running: bool,
	file:    string,
	vp:      viewport.Viewport,
	cur:     cursor.Cursor,
	win:     ^ncurses.Window,
	data:    Maybe(rune),
}

init_ncurses :: proc(win: ^ncurses.Window) {
	ncurses.raw()
	ncurses.noecho()
	ncurses.cbreak()
	ncurses.keypad(win, true)
}

new :: proc() -> (state: Editor_State) {
	state.win = ncurses.initscr()
	init_ncurses(state.win)
	state.running = true
	state.mode = .normal
	y, x := ncurses.getmaxyx(state.win)
	state.cur = {
		max_row = cast(u16)x,
		max_col = cast(u16)y,
	}
	state.vp = default_viewport()
	state.buffer = nil
	state.data = nil
	return state
}

getmaxxy :: proc() -> cursor.Cursor {
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	cur := cursor.Cursor {
		max_row = cast(u16)x,
		max_col = cast(u16)y,
	}
	return cur
}

set_editor_buffer :: proc(state: ^Editor_State, buffer: Buffer) {
	state.buffer = buffer
}

default_viewport :: proc() -> viewport.Viewport {
	return viewport.new(buffer = {})
}

set_viewport :: proc(state: ^Editor_State, vp: viewport.Viewport) {
	state.vp = vp
}

handle_mode :: proc(state: ^Editor_State) {
	switch state.mode {
	case .normal:
		handle_normal_mode(state)
	case .insert:
		handle_insert_mode(state)
	}
}

@(private)
handle_normal_mode :: proc(editor_state: ^Editor_State) {
	if editor_state.data != nil {
		key := ncurses.keyname(i32(editor_state.data.(rune)))
		if key == "^Q" {
			editor_state.running = false
			return
		}
		switch (key) {
		case "a", "h", "KEY_LEFT":
			cursor.move(&editor_state.cur, .left)
		case "d", "l", "KEY_RIGHT":
			cursor.move(&editor_state.cur, .right)
		case "w", "k", "KEY_UP":
			cursor.move(&editor_state.cur, .up)
		case "s", "j", "KEY_DOWN":
			cursor.move(&editor_state.cur, .down)
		case "g":
			cursor.move(&editor_state.cur, .column_end)
		case "G":
			cursor.move(&editor_state.cur, .column_top)
		case "i":
			editor_state.mode = .insert
		case "KEY_RESIZE":
			y, x := ncurses.getmaxyx(ncurses.stdscr)
			editor_state.cur.max_col = u16(y)
			editor_state.cur.max_row = u16(x)
		case "KEY_BACKSPACE":
			cursor.move(&editor_state.cur, .left)
		case "KEY_ENTER":
			cursor.move(&editor_state.cur, .down)
		}
	}
	// TODO: handle ^I and ^J, ^I is tab and ^J is enter 
	viewport.render(&editor_state.vp)
	return
}

@(private)
handle_insert_mode :: proc(editor_state: ^Editor_State) {
	if editor_state.data != nil {
		key := ncurses.keyname(i32(editor_state.data.(rune)))
		switch key {
		case "KEY_LEFT":
			cursor.move(&editor_state.cur, .left)
		case "KEY_RIGHT":
			cursor.move(&editor_state.cur, .right)
		case "KEY_UP":
			cursor.move(&editor_state.cur, .up)
		case "KEY_DOWN":
			cursor.move(&editor_state.cur, .down)
		case "KEY_RESIZE":
			y, x := ncurses.getmaxyx(ncurses.stdscr)
			editor_state.cur.max_col = u16(y)
			editor_state.cur.max_row = u16(x)
		case "KEY_BACKSPACE":
			// backspace key
			if is_empty_buffer(editor_state.buffer, editor_state.cur.col) {
				ordered_remove(&editor_state.buffer, cast(int)editor_state.cur.col)
				cursor.move(&editor_state.cur, .up)
				log.info(string(editor_state.buffer[editor_state.cur.col].buf[:]))
			} else {
				append_at(&editor_state.buffer, editor_state.cur.col, string_to_dyn_arr(" "))
				cursor.move(&editor_state.cur, .left)
				log.info(buffer_index_to_string(editor_state.buffer, editor_state.cur.col))
			}
		case "^J":
			// ENTER key
			buf: [dynamic]byte = {'\n'}
			inject_at(
				&editor_state.buffer,
				cast(int)editor_state.cur.col + 1,
				strings.Builder{buf},
			)
			cursor.move(&editor_state.cur, .down)
		case "^C", "^[":
			// CTRL+C and ESCAPE
			editor_state.mode = .normal
		case:
			assign_at(
				&editor_state.buffer[editor_state.cur.col].buf,
				cast(int)editor_state.cur.row,
				u8(editor_state.data.(rune)),
			)
			log.info(key)
			cursor.move(&editor_state.cur, .right)
			ncurses.refresh()
		}
	}
	viewport.render(&editor_state.vp)
}

render_screen :: proc(editor: ^Editor_State) {
	handle_mode(editor)
	ncurses.move(cast(i32)editor.cur.col, cast(i32)editor.cur.row)
	ncurses.refresh()
}
