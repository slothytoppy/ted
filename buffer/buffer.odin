package buffer

import "core:log"
import "core:os"

Line :: #type [dynamic]byte

Buffer :: #type [dynamic]Line

count_lines :: proc(data: []byte) -> (lines_count: int) {
	for b in data {
		if b == '\n' {
			lines_count += 1
		}
	}
	return lines_count
}

make_renderable :: proc(buffer: ^Buffer) {
	for &line in buffer {
		append(&line, 0)
	}
}

@(require_results)
load_buffer_from_file :: proc(file: string) -> Buffer {
	data, err := os.read_entire_file_from_filename(file)
	if err == false {
		return {}
	}
	buffer := make(Buffer, count_lines(data))
	last_line: i32 = 0
	cursor := 0
	for b, i in data {
		if b == '\n' {
			if data[last_line] == '\n' {
				last_line += 1
			}
			append(&buffer[cursor], ..data[last_line:i])
			last_line = cast(i32)i
			cursor += 1
		}
	}

	return buffer
}

write_buffer_to_file :: proc(buffer: Buffer, file: string) -> bool {
	data: [dynamic]byte
	defer delete(data)
	for line in buffer {
		append(&data, ..line[:])
		append(&data, '\n')
	}
	success := os.write_entire_file(file, data[:])
	return success
}

buffer_append_bytes_at :: proc(buffer: ^Buffer, bytes: []byte, #any_int line, offset: int) {
	inject_at(&buffer[line], offset, ..bytes)
}

buffer_append_byte_at :: proc(buffer: ^Buffer, b: byte, #any_int line, offset: int) {
	inject_at_elem(&buffer[line], offset, b)
}

buffer_assign_byte_at :: proc(buffer: ^Buffer, b: byte, #any_int line, offset: int) {
	assign_at(&buffer[line], offset, b)
}

// puts a space at position: pos in the buffer, doesnt grow or shrink the dynamic array
buffer_remove_byte_at :: proc(buffer: ^Buffer, #any_int line, offset: int) {
	assign_at(&buffer[line], offset, ' ')
}

// use bytes.split if there are performance issues
split :: proc(data: []byte, delim: byte) -> (line_idx: [dynamic]i32) {
	last_line, current_line: int
	for c, i in data {
		if c == delim {
			last_line = i
			current_line += 1
			append(&line_idx, cast(i32)i)
		}
	}
	return line_idx
}
