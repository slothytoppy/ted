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

Buffer :: struct {
	data: [dynamic]Line,
}

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
	append(&buffer.data, Line{})
	for b, i in data {
		append(&buffer.data[line], Cell{0, 0, todin.Key{rune(b), false}})
		col += 1
		if b == '\n' {
			append(&buffer.data, Line{})
			line += 1
			col = 0
		}
	}
	return buffer
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor) {
	y := saturating_sub(cursor.y, 1, 0)
	x := saturating_sub(cursor.x, 1, 0)
	offset := y
	if buffer_length(buffer^) <= 0 || is_line_empty(buffer^, y) {
		return
	}
	log.debug("line at:", offset, buffer.data[offset])
	ordered_remove(&buffer.data[offset], cast(int)x)
}

remove_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	if index > saturating_sub(buffer_length(buffer^), 1, 0) {
		return
	}
	ordered_remove(&buffer.data, cast(int)index)
}

append_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	inject_at(&buffer.data, cast(int)index + 1, Line{})
}

append_rune_to_buffer :: proc(buffer: ^Buffer, cursor: Cursor, key: rune) {
	offset := saturating_sub(cursor.y, 1, 0)
	if offset > saturating_sub(buffer_length(buffer^), 1, 0) {
		panic("attempting to write to unallocated line")
	}
	inject_at(
		&buffer.data[offset],
		cast(int)saturating_sub(cursor.x, 1, 0),
		Cell{0, 0, todin.Key{key, false}},
	)
}

buffer_length :: proc(buffer: Buffer) -> i32 {
	return cast(i32)len(buffer.data)
}

count :: proc(buffer: Buffer, char: rune) -> (count: i32) {
	for line in buffer.data {
		for cell in line {
			if cell.datum.keyname == char {
				count += 1
			}
		}
	}
	return count
}

is_line_empty :: proc(buffer: Buffer, #any_int line: i32) -> bool {
	if line > buffer_length(buffer) {
		return true
	}
	if len(buffer.data[line]) > 0 {
		return false
	}
	return true
}
