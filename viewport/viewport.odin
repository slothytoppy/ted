package viewport

import "../cursor"
import "../deps/ncurses"
import "core:fmt"
import "core:log"

// scroll command
Command :: enum {
	up,
	down,
}

Pos :: struct {
	max_x, max_y, scroll_y: i32,
}

Viewport :: struct {
	// is the max x,y
	cursor:    cursor.Cursor,
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

scroll_up :: proc(viewport: Viewport) -> (vp: Viewport) {
	vp = viewport
	if viewport.scroll_y > 0 {
		vp.scroll_y -= 1
		return vp
	}
	return viewport
}

scroll_down :: proc(viewport: Viewport, #any_int lines_count: i32) -> (vp: Viewport) {
	vp = viewport
	if vp.scroll_y + vp.max_y < lines_count {
		vp.scroll_y += 1
		return vp
	}
	return viewport
}

render :: proc(vp: ^Viewport, data: [dynamic][dynamic]byte) {
	// erase so that i rerender to an empty screen, only needed for scrolling
	ncurses.erase()
	ncurses.move(0, 0)

	if cursor.should_scroll(vp.cursor, .up) {
		vp^ = scroll_up(vp^)
	} else if cursor.should_scroll(vp.cursor, .down) {
		vp^ = scroll_down(vp^, len(data))
	}
	cursor: i32 = 0
	for i in 0 ..< vp.max_y {
		i := i
		i += vp.scroll_y
		if i > vp.scroll_y + vp.max_y {
			break
		}
		if i > cast(i32)len(data) {
			break
		}
		line_len := min(cast(i32)len(data[i]), vp.max_y)
		ncurses.mvprintw(cursor, 0, "%s", fmt.ctprint(string(data[i][:line_len])))
		cursor += 1
		log.info(data[i])
	}
	ncurses.refresh()
}

should_scroll :: proc(#any_int y, max_y: i32) -> bool {
	return y > max_y
}
