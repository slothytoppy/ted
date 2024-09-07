package buffer

import "core:log"
import "core:os"
import "core:testing"
import "core:unicode/utf8"

Cell :: struct {
	fg, bg: int,
	datum:  rune,
}

Line :: [dynamic]Cell

Buffer :: [dynamic]Line

init_buffer :: proc {
	read_file_from_string,
	read_file_from_data,
}

read_file :: proc {
	read_file_from_string,
	read_file_from_data,
}

init_buffer_with_empty_lines :: proc(#any_int lines: i32) -> (buffer: Buffer) {
	inject_at(&buffer, cast(int)lines, Line{})
	return buffer
}

@(require_results)
read_file_from_string :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file_from_filename(file)
	if err == false {
		log.info("file does not exist")
		return {}
	}
	defer delete(data)
	return read_file_from_data(data)
}

@(require_results)
read_file_from_data :: proc(data: []byte) -> (buffer: Buffer) {
	line, col: int
	append(&buffer, Line{})
	runes := utf8.string_to_runes(string(data[:]))
	defer delete(runes)
	for b in runes {
		append(&buffer[line], Cell{0, 0, b})
		col += 1
		if b == '\n' {
			append(&buffer, Line{})
			line += 1
			col = 0
		}
	}
	return buffer
}

append_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	inject_at(buffer, cast(int)index, Line{})
}

append_string :: proc(buffer: ^Buffer, y, x: i32, str: string) {
	offset := x
	for s in str {
		append_rune(buffer, y, offset, s)
		offset += 1
	}
}

append_rune :: proc(buffer: ^Buffer, y, x: i32, key: rune) {
	offset := y
	if offset >= saturating_sub(buffer_length(buffer^), 1, 0) {
		append_line(buffer, offset + 1)
	}
	inject_at(&buffer[offset], cast(int)x, Cell{0, 0, key})
}

delete_char :: proc(line: ^Line, x: i32) {
	x := saturating_sub(x, 1, 0)
	offset := x
	if len(line) <= 0 || x >= cast(i32)len(line) {
		return
	}
	log.debug("line at:", offset, line)
	ordered_remove(line, cast(int)offset)
}

delete_buffer :: proc(buffer: ^Buffer) {
	clear(buffer)
}

delete_line :: proc(line: ^Line) {
	clear(line)
}

remove_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	if index >= saturating_sub(buffer_length(buffer^), 1, 0) {
		return
	}
	ordered_remove(buffer, cast(int)index)
}

write_buffer_to_file :: proc(buffer: Buffer, file: string) {
	bytes: [dynamic]byte
	for line in buffer {
		for cell in line {
			append(&bytes, byte(cell.datum))
		}
	}
	os.write_entire_file(file, bytes[:])
}

buffer_length :: proc(buffer: Buffer) -> i32 {
	return cast(i32)len(buffer)
}

line_length :: proc(buffer: Buffer, #any_int line: i32) -> i32 {
	idx := line
	if idx >= saturating_sub(buffer_length(buffer), 1, 0) {
		return -1
	}
	return saturating_sub(cast(i32)len(buffer[idx]), 1, 0)
}

is_line_empty :: proc(buffer: Buffer, #any_int line: i32) -> bool {
	if line > saturating_sub(buffer_length(buffer), 1, 0) || len(buffer[line]) == 0 {
		return true
	}
	return false
}

line_to_string :: proc(line: Line) -> string {
	bytes: [dynamic]byte
	for cell in line {
		append(&bytes, byte(cell.datum))
	}
	return string(bytes[:])
}

saturating_sub :: proc(val, amount, min: $T) -> T {
	if val > 0 && val - amount > min {
		return val - amount
	}
	return min
}

@(test)
init_buffer_test :: proc(t: ^testing.T) {
	file_name := "test_file"
	fd, err := os.open(file_name, os.O_CREATE | os.O_RDONLY, 0644)
	defer {
		os.close(fd)
		os.remove(file_name)
	}
	if err != nil {
		return
	}
	buffer := init_buffer(file_name)
	defer delete_buffer(&buffer)
	assert(len(buffer) == 0)
}

@(test)
remove_buffer_test :: proc(t: ^testing.T) {
	buffer: Buffer
	append_rune(&buffer, 10, 1, 'r')
	delete_buffer(&buffer)
	assert(len(buffer) == 0)
}

@(test)
line_to_string_test :: proc(t: ^testing.T) {
	buffer: Buffer
	defer delete_buffer(&buffer)
	append_string(&buffer, 0, 0, "hello")
	str := line_to_string(buffer[0])
	log.info("STR:", str)
	log.info(buffer[0])
	assert(str == "hello")
}
