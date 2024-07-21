package viewport

import "../deps/ncurses"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"

Command :: enum {
	up,
	down,
}

Pos :: struct {
	x, y, scroll_y: i32,
}

Viewport :: struct {
	// is the max x,y
	using pos: Pos,
}

set_max_pos :: proc(vp: ^Viewport, max_x, max_y: i32) {
	vp.pos = {max_x, max_y, 0}
}

// use bytes.count if there are performance issues
count :: proc(data: []byte, delim: byte) -> (c: int) {
	for b in data {
		if delim == b {
			c += 1
		}
	}
	return c
}

// use bytes.split if there are performance issues
split :: proc(data: []byte, delim: byte) -> (buf: [][]byte) {
	n := count(data, delim)
	sep := make([][]byte, n)
	total_lines := 0
	last_byte := 0
	current_byte := 0
	for b, i in data {
		current_byte += 1
		if b == delim {
			sep[total_lines] = data[last_byte:i]
			total_lines += 1
			last_byte = current_byte
		}
	}
	return sep[:total_lines][:]
}

render :: proc(vp: ^Viewport, data: []byte, command: Command) {
	// TODO: line wrapping
	// erase so that i rerender to an empty screen, only needed for scrolling
	ncurses.erase()
	ncurses.move(0, 0)

	buf := split(data[:], '\n')
	lines_count: i32 = cast(i32)len(buf)

	cursor: i32 = 0
	log.info("lines count:", len(buf))

	switch command {
	case .up:
		if vp.pos.scroll_y > 0 {
			vp.pos.scroll_y -= 1
			log.info("scroll decreased to", vp.pos.scroll_y)
		}
	case .down:
		if vp.pos.scroll_y + vp.y < lines_count {
			vp.pos.scroll_y += 1
			log.info("scroll increased to", vp.pos.scroll_y)
		}
	}

	for i in 0 ..< vp.y {
		i := cast(i32)i + vp.scroll_y
		if i > vp.scroll_y + vp.y {
			break
		}
		log.info(i)
		if i > cast(i32)len(buf) - 1 || i > lines_count {
			break
		}
		line_len := min(cast(i32)len(buf[i]), vp.x)
		ncurses.printw("%s", fmt.ctprint(cast(string)buf[i][:line_len]))
		ncurses.move(cursor + 1, 0)
		cursor += 1
	}

	ncurses.refresh()
}

should_scroll :: proc(#any_int y, max_y: i32) -> bool {
	return y > max_y
}
