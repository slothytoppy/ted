package editor

import "core:log"
import "core:testing"

// holds metadata about the open file
TextBuffer :: struct {
	line_idx: [dynamic]int,
}

@(private)
fill_text_buffer_line_indexes :: proc(text_buffer: ^TextBuffer, buffer: Buffer) {
	for cell, i in buffer {
		if cell.datum.keyname == '\n' {
			append(&text_buffer.line_idx, i)
		}
	}
}

init_text_buffer :: proc(buffer: Buffer) -> (text_buffer: TextBuffer) {
	fill_text_buffer_line_indexes(&text_buffer, buffer)
	return text_buffer
}

get_lines_indexes :: proc(text_buffer: ^TextBuffer, buffer: Buffer) {
	if len(text_buffer.line_idx) > 0 {
		delete(text_buffer.line_idx)
	}
	fill_text_buffer_line_indexes(text_buffer, buffer)
}

@(private = "file")
append_new_line :: proc(text_buffer: ^TextBuffer, min, max, idx: int) -> (found: bool) {
	last_idx := 0
	for i in min ..= max {
		log.info(i)
		last_idx = text_buffer.line_idx[i]
		if idx < last_idx {
			log.info("i:", i)
			inject_at(&text_buffer.line_idx, i, idx)
			return true
		}
	}
	return false
}

insert_new_line_idx :: proc(text_buffer: ^TextBuffer, line_idx: int) {
	if len(text_buffer.line_idx) == 0 {
		append(&text_buffer.line_idx, line_idx)
		return
	}
	half_len := len(text_buffer.line_idx) / 2

	if text_buffer.line_idx[half_len] > line_idx {
		found := append_new_line(text_buffer, 0, half_len, line_idx)
		if found {
			return
		}
	} else if text_buffer.line_idx[half_len] < line_idx {
		append_new_line(text_buffer, half_len, len(text_buffer.line_idx) - 1, line_idx)
	}
}

@(test)
test_insert_new_line_idx :: proc(t: ^testing.T) {
	buffer := init_buffer_from_bytes([]byte{65, 100, 50, 40, 10, 10, 10, 10})
	text_buffer := init_text_buffer(buffer)
	insert_new_line_idx(&text_buffer, 60)
	log.info(text_buffer.line_idx)
}
