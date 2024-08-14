package editor

import "../deps/todin"
import "core:log"
import "core:os"

Cell :: struct {
	fg, bg: int,
	datum:  todin.Key,
}

Buffer :: [dynamic]Cell

init_buffer_from_file :: proc(file: string) -> (buffer: Buffer) {
	data, err := os.read_entire_file(file)
	if err == false {
		os.exit(1)
	}
	for b in data {
		key := b
		append(&buffer, Cell{0, 0, todin.Key{keyname = rune(key), control = false}})
	}
	return buffer
}

init_buffer_from_bytes :: proc(data: []byte) -> (buffer: Buffer) {
	for b in data {
		append(&buffer, Cell{0, 0, todin.Key{rune(b), false}})
	}
	return buffer
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor, viewport: Viewport) {
	line := 0
	y := 0
	for cell, i in buffer {
		if cast(i32)line == max(cursor.y - 1, 0) {
			log.info(y)
			break
		}
		switch cell.datum.keyname {
		case '\n':
			y = i
			line += 1
		}
	}
	if y + cast(int)cursor.x > len(buffer) {
		return
	}
	ordered_remove(buffer, cast(int)(y + cast(int)cursor.x))
}
