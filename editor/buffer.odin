package editor

import "../deps/todin"
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
	is_control: bool
	for b in data {
		key := b
		append(&buffer, Cell{0, 0, todin.Key{keyname = rune(key), control = is_control}})
	}
	return buffer
}
