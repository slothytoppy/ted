package buffer

import "core:log"
import "core:os"

Line :: #type [dynamic]byte

Buffer :: #type [dynamic]Line

// for counting lines in a file
count_lines :: proc(data: []byte) -> (lines_count: int) {
	for b in data {
		if b == '\n' {
			lines_count += 1
		}
	}
	return lines_count
}

@(require_results)
load_buffer_from_file :: proc(file: string) -> Buffer {
	data, err := os.read_entire_file_from_filename(file, context.temp_allocator)
	if err == false {
		log.info("failed to read file")
		buffer := make(Buffer, 1)
		return buffer
	}
	lines := max(1, count_lines(data))
	buffer := make(Buffer, lines)
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
	if file == "" {
		log.info("invalid file name")
		return false
	}
	data := make([dynamic]byte, context.temp_allocator)
	for line in buffer {
		append(&data, ..line[:])
		append(&data, '\n')
	}
	success := os.write_entire_file(file, data[:])
	log.info(data)
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

// puts a space at line and offset; doesnt grow or shrink the dynamic array
buffer_remove_byte_at :: proc(buffer: ^Buffer, #any_int line, offset: int) {
	assign_at(&buffer[line], offset, ' ')
}
