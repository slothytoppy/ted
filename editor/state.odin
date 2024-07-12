package editor

import "../cursor"
import ncurses "../deps/ncurses/src"
import "../viewport"
import "core:log"

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
	cursor:  cursor.Cursor,
}

new :: proc() -> (state: Editor_State) {
	state.running = true
	state.mode = .normal
	state.vp = default_viewport()
	state.buffer.data = nil
	return state
}

set_editor_buffer :: proc(state: ^Editor_State, buffer: Buffer) {
	state.buffer = buffer
}

default_viewport :: proc() -> viewport.Viewport {
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	return viewport.new(endx = x, endy = y, buffer = {})
}

set_viewport :: proc(state: ^Editor_State, vp: viewport.Viewport) {
	state.vp = vp
}

handle_mode :: proc(state: ^Editor_State, data: rune) {
	switch state.mode {
	case .normal:
		handle_normal_mode(state, data)
	case .insert:
		handle_insert_mode(state, data)
	}
}

@(private)
handle_insert_mode :: proc(editor_state: ^Editor_State, data: rune) {
	key := ncurses.keyname(i32(data))
	if key == "KEY_LEFT" {
		cursor.move(&editor_state.cursor, .left)
	} else if key == "KEY_RIGHT" {
		cursor.move(&editor_state.cursor, .right)
	} else if key == "KEY_UP" {
		cursor.move(&editor_state.cursor, .up)
	} else if key == "KEY_DOWN" {
		cursor.move(&editor_state.cursor, .down)
	} else if key == "KEY_RESIZE" {
		y, x := ncurses.getmaxyx(ncurses.stdscr)
		editor_state.cursor.max_col = u16(y)
		editor_state.cursor.max_row = u16(x)
	} else if key == "KEY_BACKSPACE" {
		cursor.move(&editor_state.cursor, .left)
		ncurses.delch()
	} else if key == "^C" || key == "^[" {
		editor_state.mode = .normal
	} else {
		ncurses.printw("%c", data)
		log.info(key)
		cursor.move(&editor_state.cursor, .right)
	}
	viewport.render(&editor_state.vp)
}

@(private)
handle_normal_mode :: proc(editor_state: ^Editor_State, data: rune) {
	if ncurses.keyname(i32(rune(data))) == "^Q" {
		editor_state.running = false
		return
	}
	// TODO: handle ^I and ^J, ^I is tab and ^J is enter 
	switch data {
	case 'a', 'h', ncurses.KEY_LEFT:
		cursor.move(&editor_state.cursor, .left)
	case 'd', 'l', ncurses.KEY_RIGHT:
		cursor.move(&editor_state.cursor, .right)
	case 's', 'j', ncurses.KEY_DOWN:
		cursor.move(&editor_state.cursor, .down)
	case 'w', 'k', ncurses.KEY_UP:
		cursor.move(&editor_state.cursor, .up)
	case 'g':
		cursor.move(&editor_state.cursor, .column_end)
	case 'G':
		cursor.move(&editor_state.cursor, .column_top)
	case 'i':
		editor_state.mode = .insert
	case ncurses.KEY_RESIZE:
		y, x := ncurses.getmaxyx(ncurses.stdscr)
		editor_state.cursor.max_col = u16(y)
		editor_state.cursor.max_row = u16(x)
	}
	viewport.render(&editor_state.vp)
	return
}
