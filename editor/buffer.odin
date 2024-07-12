package editor

import "core:os"
import "core:strings"

Buffer :: struct {
	data: [dynamic]string,
}

// loads all of the file into the buffer
load_file_into_buffer :: proc(path: string) -> Buffer {
	if !os.exists(path) {
		panic("file path doesnt exist")
	}
	buffer: Buffer
	data, _ := os.read_entire_file_from_filename(path)
	data_strings := strings.split(string(data), "\n")
	append(&buffer.data, ..data_strings)
	return buffer
}

load_bytes_into_buffer :: proc(bytes: []byte) -> (buffer: Buffer) {
	append(&buffer.data, string(bytes[:]))
	return buffer
}
