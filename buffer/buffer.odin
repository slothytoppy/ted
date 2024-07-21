package buffer

import "core:os"

Buffer :: #type [dynamic]byte

@(require_results)
load_buffer_from_file :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file_from_filename(file)
	if err == false {
		return {}
	}
	append(&buffer, ..data[:])
	return buffer
}

buffer_append_byte_at :: proc(buffer: ^Buffer, b: byte, #any_int pos: int) {
	inject_at(buffer, pos, b)
}

buffer_assign_byte_at :: proc(buffer: ^Buffer, b: byte, #any_int pos: int) {
	assign_at(buffer, pos, b)
}

// puts a space at position: pos in the buffer, doesnt grow or shrink the dynamic array
buffer_remove_byte_at :: proc(buffer: ^Buffer, #any_int pos: int) {
	assign_at(buffer, pos, ' ')
}

@(require_results)
get_line_index :: proc(buffer: Buffer, #any_int line: i32) -> i32 {
	current_line: i32 = 0
	current_byte: i32 = 0
	for b in buffer {
		if b == '\n' {
			if current_line == line {
				return current_line * current_byte
			}
			current_line += 1
		}
		current_byte += 1
	}
	return 0
}

// use bytes.count if there are performance issues
@(require_results)
count :: proc(data: []byte, delim: byte) -> (c: int) {
	for b in data {
		if delim == b {
			c += 1
		}
	}
	return c
}

// use bytes.split if there are performance issues
@(require_results)
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
