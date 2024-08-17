package editor

import "../deps/todin"
import "core:log"
import "core:os"
import "core:unicode/utf8"

Cell :: struct {
	fg, bg: int,
	datum:  todin.Key,
}

//Buffer :: [dynamic]Cell
Buffer :: struct {
	data:     [dynamic]Cell,
	metadata: struct {
		line_start, line_end: [dynamic]u16,
	},
}

init_buffer_from_file :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file(file)
	if err == false {
		os.exit(1)
	}
	if len(data) <= 0 && err == true {
		unimplemented_contextless()
	}
	defer delete(data)
	append(&buffer.metadata.line_start, 0)
	for b, i in data {
		key := b
		append(&buffer.data, Cell{0, 0, todin.Key{keyname = rune(key), control = false}})
		if b == '\n' {
			append(&buffer.metadata.line_end, cast(u16)i)
			append(&buffer.metadata.line_start, cast(u16)i + 1)
		}
	}
	return buffer
}

init_buffer_from_bytes :: proc(data: []byte) -> (buffer: Buffer) {
	for b, i in data {
		append(&buffer.data, Cell{0, 0, todin.Key{rune(b), false}})
		if b == '\n' {
			append(&buffer.metadata.line_end, cast(u16)i)
			append(&buffer.metadata.line_start, cast(u16)i + 1)
		}
	}
	return buffer
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor) {
	if len(buffer.data) <= 0 ||
	   len(buffer.metadata.line_end) <= 0 ||
	   len(buffer.metadata.line_start) <= 0 {
		return
	}
	offset := buffer.metadata.line_start[cast(u16)max(cursor.y - 1, 0)] + cast(u16)cursor.x
	if offset >= buffer.metadata.line_end[cast(u16)max(len(buffer.metadata.line_end) - 1, 0)] {
		log.warnf("failed to remove char because offset:%d was too large", offset)
		return
	}
	ordered_remove(
		&buffer.data,
		cast(int)buffer.metadata.line_start[max(cursor.y - 1, 0)] + cast(int)cursor.x,
	)
}

append_rune_to_buffer :: proc(buffer: ^Buffer, cursor: Cursor, key: rune) {
	offset := max(cursor.y - 1, 0)
	if cast(int)offset >= len(buffer.metadata.line_start) {
		inject_at(&buffer.metadata.line_start, cast(int)offset, cast(u16)cursor.x)
		log.info(offset)
	}
	inject_at(
		&buffer.data,
		cast(int)buffer.metadata.line_start[offset] + cast(int)cursor.x,
		Cell{0, 0, todin.Key{key, false}},
	)
}

buffer_to_string :: proc(buffer: Buffer) -> string {
	str: [dynamic]rune
	for cell in buffer.data {
		append(&str, cell.datum.keyname)
	}
	return utf8.runes_to_string(str[:])
}

runes_to_string :: proc(data: []rune) -> string {
	return utf8.runes_to_string(data[:])
}
