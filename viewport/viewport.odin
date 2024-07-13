package viewport

import ncurses "../deps/ncurses/src"
import "core:strings"

Viewport :: struct {
	max_col, max_row: u16,
	buffer:           ^[dynamic]strings.Builder,
}

new :: proc(buffer: ^[dynamic]strings.Builder) -> Viewport {
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	return Viewport{max_row = cast(u16)x, max_col = cast(u16)y, buffer = buffer}
}

Direction :: enum {
	none,
	up,
	down,
}

render :: proc(vp: ^Viewport) {
	ncurses.move(0, 0)
	for i in 0 ..< vp.max_col {
		if i >= vp.max_col {
			break
		}
		min := 0
		max := clamp(min, len(vp.buffer[i].buf[:]), cast(int)vp.max_row)
		ncurses.printw("%s", vp.buffer[i].buf[:max])
		ncurses.move(i32(i) + 1, 0)
	}
	ncurses.refresh()
}
