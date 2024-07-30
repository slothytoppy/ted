package editor

import "../buffer"
import "../deps/ncurses"
import "core:fmt"
import "core:log"
import "core:os"

@(require_results)
read_file :: proc(path: string) -> []byte {
	data, err := os.read_entire_file_from_filename(path)
	if err != true {
		return {}
	}
	return data
}

@(require_results)
logger_init :: proc(log_file: os.Handle) -> (logger: log.Logger) {
	if log_file <= 0 {
		fd, _ := os.open("/dev/null")
		return log.create_file_logger(fd)
	}
	logger = log.create_file_logger(log_file)
	return logger
}

@(require_results)
getmaxy :: proc() -> (y: i32) {
	return ncurses.getmaxy(ncurses.stdscr)
}

@(require_results)
getmaxx :: proc() -> (x: i32) {
	return ncurses.getmaxx(ncurses.stdscr)
}

@(require_results)
getmaxxy :: proc() -> (x, y: i32) {
	y, x = ncurses.getmaxyx(ncurses.stdscr)
	return x, y}

@(require_results)
getcuryx :: proc() -> (y, x: i32) {
	x = ncurses.getcurx(ncurses.stdscr)
	y = ncurses.getcury(ncurses.stdscr)
	return y, x
}

move :: proc(#any_int y, x: i32) {
	ncurses.move(y, x)
}

@(require_results)
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

@(require_results)
load_buffer_from_file :: proc(file: string) -> buffer.Buffer {
	return buffer.load_buffer_from_file(file)
}

print :: proc(str: cstring) {
	ncurses.printw("%s", str)
}

// uses y, x for compatability with ncurses
mvprint :: proc(#any_int y, x: i32, str: cstring) {
	ncurses.mvprintw(y, x, "%s", str)
}

// removes a char at line cur_y, cur_x-1
delete_char :: proc(editor: ^Editor) {
	buffer.buffer_remove_byte_at(
		&editor.buffer,
		editor.viewport.cur_y,
		saturating_sub(editor.viewport.cur_x, 1),
	)
}

// clear and refreshes screen
clear_screen :: proc() {
	ncurses.erase()
	ncurses.refresh()
}

refresh_screen :: proc() {
	ncurses.refresh()
}

// helper for taking in some argument and turning it into a cstring
@(require_results)
format_to_cstring :: proc(args: ..any) -> cstring {
	return fmt.ctprint(..args)
}

@(require_results)
editor_max :: proc(#any_int val, max_value: i32) -> i32 {
	if max_value > val {
		return val
	}
	if max_value == 0 && val > 0 {
		return val
	}
	return max_value
}

@(require_results)
saturating_sub :: proc(#any_int a, b: i32) -> i32 {
	if a - b > 0 {
		return a - b
	}
	return 0
}

@(require_results)
saturating_add :: proc(#any_int val, amount, max: i32) -> i32 {
	if val + amount < max {
		return val + amount
	}
	return max
}
