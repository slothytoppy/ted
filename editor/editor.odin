package editor

import "../deps/ncurses/"
import "../viewport"
import "core:os"

Buffer :: #type [dynamic]byte

Editor :: struct {
	pos:      [2]i32,
	viewport: viewport.Viewport,
	buffer:   Buffer,
}

init_editor :: proc() -> Editor {
	ncurses.initscr()
	ncurses.noecho()
	ncurses.raw()
	return {}
}

deinit_editor :: proc() {
	ncurses.endwin()
	ncurses.echo()
	ncurses.noraw()
}

load_buffer_from_file :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file_from_filename(file)
	if err != true {
		return {}
	}
	append(&buffer, ..data[:])
	return buffer
}

render :: proc(ed: Editor) {
	viewport.render(ed.viewport)
}
