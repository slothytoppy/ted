package editor

import "../buffer"
import "../deps/ncurses"
import "core:fmt"
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

getmaxxy :: proc() -> (x, y: i32) {
	y, x = ncurses.getmaxyx(ncurses.stdscr)
	return x, y}

getcuryx :: proc() -> (y, x: i32) {
	x = ncurses.getcurx(ncurses.stdscr)
	y = ncurses.getcury(ncurses.stdscr)
	return y, x
}

move :: proc(#any_int y, x: i32) {
	ncurses.move(y, x)
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

load_buffer_from_file :: proc(file: string) -> buffer.Buffer {
	return buffer.load_buffer_from_file(file)
}

// uses y, x for compatability with ncurses
mvprint :: proc(#any_int y, x: i32, str: cstring) {
	ncurses.mvprintw(y, x, "%s", str)
}

// clear and refreshes screen
clear_screen :: proc() {
	ncurses.clear()
	ncurses.refresh()
}

refresh_screen :: proc() {
	ncurses.refresh()
}

// helper for taking in some argument and turning it into a cstring
format_to_cstring :: proc(args: ..any) -> cstring {
	return fmt.ctprint(..args)
}

editor_max :: proc(#any_int val, max_value: i32) -> i32 {
	if max_value > val {
		return val
	}
	if max_value == 0 && val > 0 {
		return val
	}
	return max_value
}
