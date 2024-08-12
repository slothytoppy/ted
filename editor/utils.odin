package editor

import "../buffer"
import "core:log"
import "core:os"

@(require_results)
read_file :: proc(path: string) -> []byte {
	data, err := os.read_entire_file_from_filename(path)
	if err != true {
		return {}
	}
	return data
}

@(require_results)
logger_init :: proc(log_file: os.Handle) -> (logger: log.Logger) {
	if log_file <= 0 {
		fd, _ := os.open("/dev/null")
		return log.create_file_logger(fd)
	}
	logger = log.create_file_logger(log_file)
	return logger
}

@(require_results)
load_buffer_from_file :: proc(file: string) -> buffer.Buffer {
	return buffer.load_buffer_from_file(file)
}

// removes a char at line cur_y, cur_x-1
delete_char :: proc(editor: ^Editor) {
	editor.cursor.x = saturating_sub(editor.cursor.x, 1, 0)
	log.info(len(editor.buffer[editor.cursor.y + 1]))
	buffer.buffer_remove_byte_at(&editor.buffer, editor.cursor.y + 1, editor.cursor.x)
}

@(require_results)
editor_max :: proc(#any_int val, max_value: i32) -> i32 {
	if max_value > val {
		return val
	}
	if max_value == 0 && val > 0 {
		return val
	}
	return max_value
}

@(require_results)
saturating_sub :: proc(#any_int val, amount, max: i32) -> i32 {
	if val - amount > max {
		log.info("val-amount:", val - amount)
		return val - amount
	}
	log.info("max:", max)
	return max
}

@(require_results)
saturating_add :: proc(#any_int val, amount, max: i32) -> i32 {
	if val + amount < max {
		return val + amount
	}
	return max
}
