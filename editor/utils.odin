package editor

import "../deps/ncurses"
import "core:log"
import "core:os"

read_file :: proc(path: string) -> []byte {
	data, err := os.read_entire_file_from_filename(path)
	if err != true {
		return {}
	}
	return data
}

logger_init :: proc(log_file: string) -> (logger: log.Logger, result: bool) {
	fd, err := os.open(log_file, os.O_CREATE | os.O_WRONLY, 0o644)
	if err != os.ERROR_NONE {
		return {}, false
	}
	logger = log.create_file_logger(fd)
	return logger, true
}

getmaxy :: proc() -> (y: i32) {
	return ncurses.getmaxy(ncurses.stdscr)
}

getmaxx :: proc() -> (x: i32) {
	return ncurses.getmaxx(ncurses.stdscr)
}

getmaxyx :: proc() -> (y, x: i32) {
	return ncurses.getmaxyx(ncurses.stdscr)
}

getcuryx :: proc() -> (y, x: i32) {
	x = ncurses.getcurx(ncurses.stdscr)
	y = ncurses.getcury(ncurses.stdscr)
	return y, x
}

init_ncurses :: proc() -> (window: ^ncurses.Window) {
	window = ncurses.initscr()
	ncurses.keypad(ncurses.stdscr, true)
	ncurses.raw()
	ncurses.noecho()
	return window
}

deinit_ncurses :: proc() {
	ncurses.endwin()
}
