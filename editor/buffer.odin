package editor

import "../todin"
import "core:log"
import "core:os"
import "core:unicode/utf8"

Cell :: struct {
	fg, bg: int,
	datum:  todin.Key,
}

Line :: [dynamic]Cell

Buffer :: [dynamic]Line

init_buffer :: proc {
	init_buffer_from_file,
	init_buffer_from_bytes,
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

init_buffer_from_bytes :: proc(data: []byte) -> (buffer: Buffer) {
	line := 0
	col := 0
	append(&buffer, Line{})
	for b, i in data {
		append(&buffer[line], Cell{0, 0, todin.Key{rune(b), false}})
		col += 1
		if b == '\n' {
			append(&buffer, Line{})
			line += 1
			col = 0
		}
	}
	return buffer
}

init_buffer_with_empty_lines :: proc(#any_int lines: i32) -> (buffer: Buffer) {
	inject_at(&buffer, cast(int)lines, Line{})
	return buffer
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor) {
	y := saturating_sub(cursor.y, 1, 0)
	x := saturating_sub(cursor.x, 1, 0)
	offset := y
	if buffer_length(buffer^) <= 0 || is_line_empty(buffer^, y) {
		return
	}
	log.debug("line at:", offset, buffer[offset])
	ordered_remove(&buffer[offset], cast(int)x)
}

remove_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	if index >= saturating_sub(buffer_length(buffer^), 1, 0) {
		return
	}
	ordered_remove(buffer, cast(int)index)
}

append_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	inject_at(buffer, cast(int)index + 1, Line{})
}

append_rune_to_buffer :: proc(buffer: ^Buffer, cursor: Cursor, key: rune) {
	offset := saturating_sub(cursor.y, 1, 0)
	if offset > saturating_sub(buffer_length(buffer^), 1, 0) {
		panic("attempting to write to unallocated line")
	}
	inject_at(&buffer[offset], cast(int)cursor.x, Cell{0, 0, todin.Key{key, false}})
}

buffer_length :: proc(buffer: Buffer) -> i32 {
	return cast(i32)len(buffer)
}

count :: proc(buffer: Buffer, char: rune) -> (count: i32) {
	for line in buffer {
		for cell in line {
			if cell.datum.keyname == char {
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
	if line > saturating_sub(buffer_length(buffer), 1, 0) {
		return true
	}
	if len(buffer[line]) > 0 {
		return false
	}
	return true
}
