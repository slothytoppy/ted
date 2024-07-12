package editor

import ncurses "../deps/ncurses/src"
import "../viewport"

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
}

new :: proc() -> (state: Editor_State) {
	state.vp = default_viewport()
	state.buffer.data = nil
	return state
}

set_editor_buffer :: proc(state: ^Editor_State, buffer: Buffer) {
	state.buffer = buffer
}

default_viewport :: proc() -> viewport.Viewport {
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	return viewport.new(endx = x, endy = y)
}

set_viewport :: proc(state: ^Editor_State, vp: viewport.Viewport) {
	state.vp = vp
}
