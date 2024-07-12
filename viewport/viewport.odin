package viewport

import ncurses "../deps/ncurses/src"

Viewport :: struct {
	startx, starty, endx, endy: i32,
	buffer:                     []string,
}

new :: proc(startx: i32 = 0, starty: i32 = 0, endx, endy: i32) -> Viewport {
	return Viewport{startx, starty, endx, endy, {}}
}

Direction :: enum {
	up,
	down,
}

scroll :: proc(vp: ^Viewport, direction: Direction, amount: int) {
	switch direction {
	case .down:
	case .up:
	case:
	}
	return
}

render :: proc(vp: Viewport) {
	ncurses.move(vp.starty, vp.startx)
	for buf, i in vp.buffer {
		i := cast(i32)i
		if vp.starty + i > vp.endy {
			break
		}
		ncurses.printw("%s", buf)
		ncurses.move(vp.starty + i, 0)
	}
	ncurses.refresh()
}
