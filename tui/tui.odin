package tui

import "../deps/ncurses"
import "core:fmt"
import "core:log"

Cursor :: struct {
	x, y: i32,
}

Viewport :: struct {
	max_x, max_y, scroll_y: i32,
}

init :: proc() {
	ncurses.initscr()
	ncurses.keypad(ncurses.stdscr, true)
	ncurses.raw()
	ncurses.noecho()
}

deinit :: proc() {
	ncurses.endwin()
}

maxx :: proc() -> i32 {
	return ncurses.getmaxx(ncurses.stdscr)
}

maxy :: proc() -> i32 {
	return ncurses.getmaxy(ncurses.stdscr)
}

maxyx :: proc() -> (lines: i32, rows: i32) {
	return ncurses.getmaxyx(ncurses.stdscr)
}

move :: proc(#any_int y, x: i32) {
	ncurses.move(y, x)
}

refresh :: proc() {
	ncurses.refresh()
}

clear :: proc() {
	ncurses.clear()
	ncurses.refresh()
}
