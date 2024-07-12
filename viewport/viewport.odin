package viewport

import "../cursor"
import ncurses "../deps/ncurses/src"

Viewport :: struct {
	using cur: cursor.Cursor,
	buffer:    []string,
}

new :: proc(
	startx: i32 = 0,
	starty: i32 = 0,
	#any_int endx, endy: i32,
	buffer: []string,
) -> Viewport {
	return Viewport {
		row = cast(u16)startx,
		col = cast(u16)starty,
		max_row = cast(u16)endx,
		max_col = cast(u16)endy,
		buffer = buffer,
	}
}

Direction :: enum {
	up,
	down,
}

scroll :: proc(vp: ^Viewport, direction: Direction, amount: int) {
	switch direction {
	case .down:
		vp.col += 1
	case .up:
		vp.col -= 1
	}
	return
}

render :: proc(vp: ^Viewport) {
	ncurses.move(i32(vp.col), i32(vp.row))
	for buf, i in vp.buffer {
		i := cast(u16)i
		if vp.col + i > vp.max_col {
			break
		}
		ncurses.printw("%s", buf)
		ncurses.move(cast(i32)vp.col + i32(i), 0)
	}
	ncurses.refresh()
}
