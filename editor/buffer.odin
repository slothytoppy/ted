package editor

import "../todin"
import "core:log"
import "core:os"
import "core:unicode/utf8"

Cell :: struct {
	fg, bg: int,
	datum:  byte,
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
	for b, i in data {
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

append_rune_to_buffer :: proc(buffer: ^Buffer, cursor: Cursor, key: rune) {
	offset := cursor.y
	if offset > saturating_sub(buffer_length(buffer^), 1, 0) {
		panic("attempting to write to unallocated line")
	}
	inject_at(&buffer[offset], cast(int)cursor.x, Cell{0, 0, byte(key)})
}

delete_char :: proc(line: ^Line, cursor: Cursor) {
	x := saturating_sub(cursor.x, 1, 0)
	offset := x
	if len(line) <= 0 || x >= cast(i32)len(line) {
		return
	}
	log.debug("line at:", offset, line)
	ordered_remove(line, cast(int)offset)
}

delete_buffer :: proc(buffer: ^Buffer) {
	for &line in buffer {
		delete(line[:])
	}
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
			append(&bytes, cell.datum)
		}
	}
	os.write_entire_file(file, bytes[:])
}

buffer_length :: proc(buffer: Buffer) -> i32 {
	return cast(i32)len(buffer)
}

count :: proc(buffer: Buffer, char: rune) -> (count: i32) {
	for line in buffer {
		for cell in line {
			if rune(cell.datum) == char {
				count += 1
			}
		}
	}
	return count
}

line_length :: proc(buffer: Buffer, #any_int line: i32) -> i32 {
	if line > buffer_length(buffer) {
		return 0
	}
	return saturating_sub(cast(i32)len(buffer[line]), 1, 0)
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
		bytes[i] = cell.datum
	}
	return string(bytes)
}
