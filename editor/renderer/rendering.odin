package renderer

import "../../todin"
import "../buffer"
import "../command_line"
import "../cursor"
import "../status_line"
import "../viewport"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:strconv"
import "core:strings"

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
	cursor:       cursor.Cursor,
	buffer:       buffer.Buffer,
	viewport:     viewport.Viewport,
	mode:         status_line.EditorMode,
	command_line: command_line.CommandLine,
}

write_to_double_buffer :: proc(buff: []buffer.Line, double_buffer: ^RenderBuffer, idx := 0) {
	idx := idx
	for line in buff {
		for cell in line {
			if idx >= len(double_buffer.cells) - 1 {
				break
			}
			switch cell.datum {
			case '\t':
				idx += 1
			case '\n':
			case:
				double_buffer.cells[idx].datum = cell.datum
				idx += 1
			}
		}
		for i in len(line) ..= _width {
			if idx >= len(double_buffer.cells) {
				break
			}
			double_buffer.cells[idx].datum = ' '
			idx += 1
		}
	}
}

render :: proc(renderable: Renderable) {
	if len(renderable.buffer) == 0 {
		return
	}
	todin.hide_cursor()
	defer todin.unhide_cursor()

	curr_buff := render_buffer[0]
	viewport := renderable.viewport
	idx := 0
	buffer_len := saturating_sub(buffer.buffer_length(renderable.buffer), 1, 0)
	height := viewport.max_y
	renderable_amount := min(buffer_len, height)
	write_to_double_buffer(
		renderable.buffer[viewport.scroll:renderable_amount + viewport.scroll],
		&curr_buff,
		idx,
	)

	status_line := status_line.write_status_line(
		renderable.mode,
		renderable.current_file,
		renderable.cursor,
		viewport.scroll,
	)
	defer delete(status_line)
	status_line_start := _width * cast(int)viewport.max_y
	for s, i in status_line {
		curr_buff.cells[status_line_start + i] = RenderCell{s}
	}

	command_line := command_line.print_command_line(renderable.command_line)
	defer delete(command_line)
	command_line_start := _width * cast(int)viewport.max_y + _width
	if renderable.mode == .command {
		curr_buff.cells[command_line_start] = RenderCell{':'}
		for s, i in command_line {
			curr_buff.cells[command_line_start + i + 1] = RenderCell{s}
		}
	}

	diffs := get_diffs()
	defer delete(diffs)

	slice.swap(render_buffer[:], 1, 0)
	slice.fill(render_buffer[0].cells[status_line_start:], RenderCell{' '})

	render_diffs(diffs, viewport)

	x := renderable.cursor.x
	if x + 6 < viewport.max_x {
		x += 6
	}
	todin.move(renderable.cursor.y, x)
}

@(private = "file")
render_diffs :: proc(diffs: [dynamic]Changed, viewport: viewport.Viewport) {
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
