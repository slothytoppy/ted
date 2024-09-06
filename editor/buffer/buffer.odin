package buffer

import "core:log"
import "core:os"
import "core:unicode/utf8"

Cell :: struct {
	fg, bg: int,
	datum:  rune,
}

Line :: [dynamic]Cell

Buffer :: [dynamic]Line

init_buffer :: proc {
	init_buffer_from_file,
	init_buffer_from_bytes,
}

read_file :: proc {
	read_file_from_string,
	read_file_from_data,
}

init_buffer_from_file :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file(file)
	if err == false {
		log.warn("failed to read", file)
		return
	}
	buffer = init_buffer_from_bytes(data)
	defer delete(data)
	log.info(data, buffer)
	return buffer
}

init_buffer_from_bytes :: read_file_from_data

init_buffer_with_empty_lines :: proc(#any_int lines: i32) -> (buffer: Buffer) {
	inject_at(&buffer, cast(int)lines, Line{})
	return buffer
}

read_file_from_string :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file_from_filename(file)
	if err == false {
		log.info("file does not exist")
		return {}
	}
	return read_file_from_data(data)
}

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

append_rune :: proc(buffer: ^Buffer, y, x: i32, key: rune) {
	offset := y
	if offset > saturating_sub(buffer_length(buffer^), 1, 0) {
		panic("attempting to write to unallocated line")
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
	delete(buffer[:])
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
	bytes := make([]byte, len(line))
	for cell, i in line {
		bytes[i] = byte(cell.datum)
	}
	return string(bytes)
}

saturating_sub :: proc(val, amount, min: $T) -> T {
	if val > 0 && val - amount > min {
		return val - amount
	}
	return min
}
