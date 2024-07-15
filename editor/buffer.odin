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
			strings.write_string(&buffer[i], strings.repeat(" ", 4))
		}
		if len(data) > 0 {
			strings.write_string(&buffer[i], data)
		} else {
			strings.write_rune(&buffer[i], '\n')
		}
	}
	return buffer
}

len_at :: proc(buffer: Buffer, #any_int idx: int) -> int {
	return len(buffer[idx].buf)
}

string_to_dyn_arr :: proc(s: string) -> (b_arr: [dynamic]byte) {
	append(&b_arr, ..transmute([]byte)s)
	return b_arr
}

// appends a Buffer to at an index to the ^Buffer
append_at :: proc(buffer: ^Buffer, #any_int idx: int, data: [dynamic]byte) {
	inject_at(buffer, idx, strings.Builder{data})
}

// deletes an array of the ^Buffer
delete_at :: proc(buffer: ^Buffer, #any_int idx: int) {
	ordered_remove(buffer, idx)
}

is_empty_buffer :: proc(buffer: Buffer, #any_int idx: int) -> bool {
	if len(buffer[idx].buf) <= 0 {
		return true
	}
	return false
}

buffer_index_to_string :: proc(buffer: Buffer, #any_int idx: int) -> string {
	return string(buffer[idx].buf[:])
}
