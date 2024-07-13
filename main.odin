package main

import "./event"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sync/chan"
import ncurses "deps/ncurses/src"
import "editor"
import "viewport"

Thread_Data :: struct {
	channel: chan.Chan(rune),
}

Args_Error :: enum {
	none,
	no_args,
	file_does_not_exist,
}

check_args :: proc(argv: []string) -> Args_Error {
	if len(argv) <= 0 {
		return .no_args
	}
	if !os.exists(argv[0]) {
		return .file_does_not_exist
	}
	return .none
}

fd_to_file_logger :: proc(fd: os.Handle) -> log.Logger {
	return log.create_file_logger(fd)
}

main :: proc() {
	args_info: editor.Args_Info
	editor.handle_args(&args_info, os.args)
	context.logger = fd_to_file_logger(args_info.log_file)
	log.info(args_info)

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
