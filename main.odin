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

main :: proc() {
	cli_args := os.args[1:]
	if len(cli_args) <= 0 {
		panic("file to edit was not given")
	}
	if !os.exists(cli_args[0]) {
		panic(fmt.tprint("file:", cli_args[0], "does not exist"))
	}

	fd, error := os.open("log", os.O_RDWR | os.O_CREATE | os.O_TRUNC, 0o611)
	if error != os.ERROR_NONE {
		panic(fmt.tprint(os.get_last_error()))
	}
	logger := log.create_file_logger(fd)
	context.logger = logger

	win := ncurses.initscr()
	state: editor.Editor_State = editor.new()
	state.buffer = editor.load_file_into_buffer(cli_args[0])
	ncurses.raw()
	ncurses.noecho()
	ncurses.cbreak()
	ncurses.keypad(win, true)
	event.poll(rune)
	state.vp = viewport.new(&state.buffer)

	//state.buffer.data = make([dynamic]strings.Builder, 0, cur.max_row)
	/*
	for data, i in state.buffer.data {
		ncurses.printw("%s", data)
		ncurses.move(i32(i + 1), 0)
	}
	cursor.move(&state.cursor, .reset)
	ncurses.refresh()
  */
	loop: for {
		data := event.poll_next().? or_continue loop
		editor.handle_mode(&state, data)
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
