package editor


/*
// holds metadata about Buffer (internal representation of an open file)
TextBuffer :: struct {
	start_line_idx: [dynamic]int,
	end_line_idx:   [dynamic]int,
}

@(private = "file")
fill_text_buffer_line_indexes :: proc(text_buffer: ^TextBuffer, buffer: Buffer) {
	append(&text_buffer.start_line_idx, 0)
	for cell, i in buffer {
		if cell.datum.keyname == '\n' {
			append(&text_buffer.end_line_idx, i)
			if i + 1 <= len(buffer) {
				append(&text_buffer.start_line_idx, i + 1)
			}
		}
	}
}

init_text_buffer :: proc(buffer: Buffer) -> (text_buffer: TextBuffer) {
	fill_text_buffer_line_indexes(&text_buffer, buffer)
	return text_buffer
}

init_empty_text_buffer :: proc(viewport: Viewport) -> (text_buffer: TextBuffer) {
	for y in 0 ..= viewport.max_y {
		append(&text_buffer.start_line_idx, 0)
		append(&text_buffer.end_line_idx, 0)
	}
	return text_buffer
}

update_lines_indexes :: proc(text_buffer: ^TextBuffer, buffer: Buffer) {
	if len(text_buffer.end_line_idx) > 0 {
		delete(text_buffer.end_line_idx)
	}
	fill_text_buffer_line_indexes(text_buffer, buffer)
}

@(private = "file")
append_new_line :: proc(text_buffer: ^TextBuffer, min, max, idx: int) -> (found: bool) {
	last_idx := 0
	for i in min ..= max {
		log.info(i)
		last_idx = text_buffer.end_line_idx[i]
		if idx < last_idx {
			log.info("i:", i)
			inject_at(&text_buffer.end_line_idx, i, idx)
			return true
		}
	}
	return false
}

insert_new_line_idx :: proc(text_buffer: ^TextBuffer, line_idx: int) {
	if len(text_buffer.end_line_idx) == 0 {
		append(&text_buffer.end_line_idx, line_idx)
		return
	}
	half_len := len(text_buffer.end_line_idx) / 2

	if text_buffer.end_line_idx[half_len] > line_idx {
		found := append_new_line(text_buffer, 0, half_len, line_idx)
		if found {
			return
		}
	} else if text_buffer.end_line_idx[half_len] < line_idx {
		append_new_line(text_buffer, half_len, len(text_buffer.end_line_idx) - 1, line_idx)
	}
}

is_text_buffer_empty :: proc(text_buffer: TextBuffer) -> bool {
	if len(text_buffer.start_line_idx) <= 0 || len(text_buffer.end_line_idx) <= 0 {
		return true
	}
	return false
}

@(test)
test_insert_new_line_idx :: proc(t: ^testing.T) {
	buffer := init_buffer_from_bytes([]byte{65, 100, 50, 40, 10, 10, 10, 10})
	text_buffer := init_text_buffer(buffer)
	insert_new_line_idx(&text_buffer, 60)
	log.info(text_buffer.end_line_idx)
}

@(test)
test_start_indexes :: proc(t: ^testing.T) {
	buffer := init_buffer_from_bytes([]byte{65, 100, 50, 40, 10, 10, 10, 10})
	text_buffer := init_text_buffer(buffer)
	insert_new_line_idx(&text_buffer, 60)
	log.info(text_buffer.start_line_idx)
}
*/
