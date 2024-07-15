package main

import "./event"
import "core:log"
import "core:os"
import ncurses "deps/ncurses/"
import "editor"
import "viewport"

fd_to_file_logger :: proc(fd: os.Handle) -> log.Logger {
	return log.create_file_logger(fd)
}

main :: proc() {
	args_info: editor.Args_Info
	editor.handle_args(&args_info, os.args)
	context.logger = fd_to_file_logger(args_info.log_file)

	win := ncurses.initscr()
	state: editor.Editor_State = editor.new()
	state.win = win
	state.buffer = editor.load_file_into_buffer(args_info.file)
	event.poll()
	state.vp = viewport.new(&state.buffer)
	loop: for {
		state.data = event.poll_next().? or_continue loop
		editor.handle_mode(&state)
		if state.running == false {
			ncurses.endwin()
			return
		}
		ncurses.move(cast(i32)state.cur.col, cast(i32)state.cur.row)
		ncurses.refresh()
	}
	ncurses.endwin()
	return
}
