package editor

import "../deps/todin"
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
	log.info(len(buffer.data))
	for line, i in buffer.data {
		for cell, idx in line {
			log.info(cell.datum.keyname)
		}
	}
	return buffer
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor) {
	if len(buffer.data) <= 0 {
		return
	}
	y := saturating_sub(cursor.y, 1, 0)
	x := saturating_sub(cursor.x, 1, 0)
	offset := y
	ordered_remove(&buffer.data[offset], cast(int)x)
}

append_line :: proc(buffer: ^Buffer, #any_int index: i32) {
	inject_at(&buffer.data, cast(int)index, Line{})
}

append_rune_to_buffer :: proc(buffer: ^Buffer, cursor: Cursor, key: rune) {
	offset := saturating_sub(cursor.y, 1, 0)
	if offset > cast(i32)len(buffer.data) - 1 {
		log.infof("offset %d is greater than %d", offset, saturating_sub(len(buffer.data), 1, 0))
	}
	log.info(buffer.data[offset], offset)
	inject_at(&buffer.data[offset], cast(int)max(cursor.x, 0), Cell{0, 0, todin.Key{key, false}})
}

buffer_to_string :: proc(buffer: Buffer) -> string {
	str: [dynamic]rune
	for cell, i in buffer.data {
		append(&str, cell[i].datum.keyname)
	}
	return utf8.runes_to_string(str[:])
}

runes_to_string :: proc(data: []rune) -> string {
	return utf8.runes_to_string(data[:])
}
