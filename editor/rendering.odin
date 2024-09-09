package editor

import "../todin"
import "buffer"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:strconv"
import "core:strings"

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
	if len(renderable.buffer) == 0 {
		return
	}
	todin.hide_cursor()

	curr_buff := render_buffer[0]
	viewport := renderable.viewport
	idx := 0
	buffer_len := saturating_sub(buffer.buffer_length(renderable.buffer), 1, 0)
	height := viewport.max_y
	renderable_amount := min(buffer_len, height)
	for line in viewport.scroll ..< renderable_amount {

		content := renderable.buffer[line]
		line_len := len(content)

		for cell in content {
			if idx >= len(curr_buff.cells) - 1 {
				break
			}
			curr_buff.cells[idx].datum = cell.datum
			idx += 1
		}

		if line_len < _width {
			for i in line_len ..< _width {
				if idx >= len(curr_buff.cells) - 1 {
					break
				}
				curr_buff.cells[idx].datum = ' '
				idx += 1
			}
		}
	}

	// place holder for proper line numbers
	format_line_len := 0
	num := len(renderable.buffer)
	for {
		num /= 10
		log.infof("num:%d", num)
		format_line_len += 1
		if num <= 0 {
			break
		}
	}

	status_line := write_status_line(
		renderable.mode,
		renderable.current_file,
		renderable.cursor,
		viewport.scroll,
	)
	defer delete(status_line)
	status_line_start := _width * cast(int)viewport.max_y
	for s, i in status_line {
		curr_buff.cells[status_line_start + i] = RenderCell{s}
		log.info(status_line_start, i)
	}

	diffs := get_diffs()
	defer delete(diffs)
	slice.swap(render_buffer[:], 1, 0)

	for diff in diffs {
		todin.move(diff.y, 0)
		line_num := format_line_num(diff.y)

		if diff.y < get_status_line_position() {
			defer delete(line_num)
			for s in line_num {
				todin.print(s)
			}
			todin.move(diff.y, diff.x + len(line_num))
		} else {
			todin.move(diff.y, diff.x)
		}

		todin.print(diff.datum.datum)

		log.debug(diff.y + 1, diff.x + 1, diff.datum.datum)
	}


	// TODO: render command line

	x := saturating_add(renderable.cursor.x, min(cast(i32)format_line_len + 4, 6), viewport.max_x)
	todin.move(renderable.cursor.y, x)
	log.info(x)
	todin.unhide_cursor()
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
	log.debug(changed_cells)
	return changed_cells
}
