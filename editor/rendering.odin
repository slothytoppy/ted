package editor

import "../todin"
import "buffer"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:strconv"
import "core:strings"

@(private = "file")
format_line_num :: proc(#any_int line_num: int) -> string {
	s := make([dynamic]byte, 6)
	slice.fill(s[:], 32)

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

	log.debug(s[:])
	return string(s[:])
}

@(private = "file")
RenderCell :: struct {
	datum: rune,
}

@(private = "file")
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

	status_line := write_status_line(
		renderable.mode,
		renderable.current_file,
		renderable.cursor,
		viewport.scroll,
	)
	defer delete(status_line)

	command_line := print_command_line(renderable.command_line)
	defer delete(command_line)

	status_line_start := _width * cast(int)viewport.max_y
	command_line_start := _width * cast(int)viewport.max_y + _width

	if len(status_line) >= _width || len(command_line) >= _width {
		return
	}

	curr_buff.cells[command_line_start] = RenderCell{':'}
	for s, i in command_line {
		curr_buff.cells[command_line_start + i + 1] = RenderCell{s}
	}
	for s, i in status_line {
		curr_buff.cells[status_line_start + i] = RenderCell{s}
		log.debug(status_line_start, i)
	}

	diffs := get_diffs()
	defer delete(diffs)
	slice.swap(render_buffer[:], 1, 0)
	slice.fill(render_buffer[0].cells[status_line_start:], RenderCell{' '})

	render_diffs(diffs, viewport)

	// TODO: render command line

	x := saturating_add(renderable.cursor.x, 6, viewport.max_x)
	todin.move(renderable.cursor.y, x)
	log.debug(x)
	todin.unhide_cursor()
}

@(private = "file")
render_diffs :: proc(diffs: [dynamic]Changed, viewport: Viewport) {
	for diff in diffs {
		todin.move(diff.y, 0)
		line_num := format_line_num(diff.y)
		defer delete(line_num)

		if diff.y < cast(int)viewport.max_y {
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
