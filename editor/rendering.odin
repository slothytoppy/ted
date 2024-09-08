package editor

import "../todin"
import "buffer"
import "core:log"
import "core:slice"
import "core:strconv"

render_buffer_line :: proc(
	line: buffer.Line,
	viewport: Viewport,
	#any_int tab_width: i32,
	cursor: Cursor = {},
) {
	for _ in 0 ..< cursor.y {
		todin.move_to_start_of_next_line()
	}
	for _ in 0 ..< cursor.x {
		todin.move_right()
	}
	for cell, idx in line {
		if cast(i32)idx > viewport.max_x - cursor.x {
			break
		}
		switch cell.datum {
		// for not printing newlines, it interferes with rendering the actual text
		case '\n':
			break
		case '\t':
			// TODO: make this configurable
			for _ in 0 ..< tab_width {
				todin.print(' ')
			}
		case:
			todin.print(rune(cell.datum))
		}
	}
}

format_line_num :: proc(#any_int line_num: int) -> string {
	s := make([dynamic]byte, 6)
	for &s, i in s {
		s = 32
	}

	//assert(line_num < 99999, "line number too big pepehands")

	//s: [6]byte = 32
	line_str := strconv.itoa(s[:], line_num)
	line_len := len(line_str)

	if line_len >= len(s) {
		return string(s[:])
	}

	right := len(s) - 1 - 1
	left := line_len - 1

	for {
		slice.swap(s[:], left, right)
		if left == 0 {
			s[saturating_sub(len(s), 1, 0)] = 32
			break
		}
		right -= 1
		left -= 1
	}
	//slice.fill(s[:len(line_str)], 32)

	log.debug(s[:])
	return string(s[:])
}

render_buffer_with_scroll :: proc(buff: buffer.Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()
	tab_width := 4
	line_num: string
	for line_idx, i in viewport.scroll ..= viewport.max_y + viewport.scroll - 1 {
		if line_idx >= saturating_sub(cast(i32)len(buff), 1, 0) || cast(i32)i >= viewport.max_y {
			break
		}
		line_num = format_line_num(line_idx)
		defer delete(line_num)
		//todin.print(line_num)
		render_buffer_line(buff[line_idx], viewport, tab_width, Cursor{x = cast(i32)len(line_num)})
		todin.move_to_start_of_next_line()
	}
}

RenderCell :: struct {
	datum: rune,
}

RenderBuffer :: struct {
	cells: [dynamic]RenderCell,
}

@(private = "file")
_width := 0
@(private = "file")
_height := 0

@(private = "file")
render_buffer: [2]RenderBuffer

init_render_buffers :: proc(#any_int width, height: int) {
	_width = width
	_height = height
	render_buffer[0] = RenderBuffer {
		cells = make([dynamic]RenderCell, width * height),
	}
	render_buffer[1] = RenderBuffer {
		cells = make([dynamic]RenderCell, width * height),
	}
}

Renderable :: struct {
	current_file: string,
	cursor:       Cursor,
	buffer:       buffer.Buffer,
	viewport:     Viewport,
	mode:         EditorMode,
	command_line: CommandLine,
}

render :: proc(renderable: Renderable) {
	log.info("RENDERED")
	curr_buff := render_buffer[0]
	viewport := renderable.viewport
	idx := 0
	for line in viewport.scroll ..< viewport.max_y {
		if line > cast(i32)len(renderable.buffer) - 1 {
			break
		}
		for cell in renderable.buffer[line] {
			curr_buff.cells[idx].datum = cell.datum
			idx += 1
		}
	}
	//log.info(curr_buff)
	diffs := get_diffs()
	slice.swap(render_buffer[:], 1, 0)
	//log.info(len(diffs))
	//log.info(diffs)
	for diff, i in diffs {
		todin.move(diff.y, diff.x)
		log.info(diff)
		todin.print(diff.datum.datum)
	}
}

Changed :: struct {
	datum: RenderCell,
	x:     int,
	y:     int,
}

get_diffs :: proc() -> [dynamic]Changed {
	changed_cells: [dynamic]Changed
	for cell, i in render_buffer[0].cells {
		y := i / _width
		x := i % _width
		prev_cell := render_buffer[1].cells[i]
		if cell != prev_cell {
			append(&changed_cells, Changed{cell, x, y})
		}
	}
	log.info(changed_cells)
	return changed_cells
}

refresh :: proc(renderable: Renderable) {
}
