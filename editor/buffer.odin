package editor

import "core:os"
import "core:strings"

Buffer :: [dynamic]strings.Builder

// loads all of the file into the buffer
load_file_into_buffer :: proc(path: string) -> Buffer {
	if !os.exists(path) {
		panic("file path doesnt exist")
	}
	data, _ := os.read_entire_file_from_filename(path)
	data_strings := strings.split(string(data), "\n")
	buffer := make(Buffer, len(data_strings))
	for data, i in data_strings {
		if data == "\t" {
			// writes 4 spaces on hitting a tab
			strings.write_string(&buffer[i], "    ")
		}
		if len(data) > 0 {
			strings.write_string(&buffer[i], data)
		} else {
			strings.write_rune(&buffer[i], '\n')
		}
	}
	return buffer
}
