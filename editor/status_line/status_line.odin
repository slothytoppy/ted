package status_line

import "../cursor"
import "core:fmt"
import "core:log"
import "core:strings"

StatusLine :: struct {
	width:       u8,
	lines_count: u32,
}

STATUS_LINE_HEIGHT :: 1

@(private = "file")
STATUS_LINE_POSITION: int

set_status_line_position :: proc(#any_int line: int) {
	STATUS_LINE_POSITION = line
}

get_status_line_position :: proc() -> int {
	return STATUS_LINE_POSITION
}

EditorMode :: enum {
	normal,
	insert,
	command,
}

@(private = "file")
editor_mode_to_str :: proc(mode: EditorMode) -> string {
	switch mode {
	case .normal:
		return "normal"
	case .insert:
		return "insert"
	case .command:
		return "command"
	}
	panic("invalid editor mode")
}

@(private = "file")
shorten_file_name :: proc(file_name: string) -> string {
	data: [dynamic]byte
	found: bool
	#reverse for r, i in file_name {
		if r == '/' || r == '\\' {
			// is a directory if it ends in `/`??
			if i >= len(file_name) {
				return ""
			}
			append(&data, file_name[i + 1:])
			found = true
			break
		}
	}
	if !found {
		append(&data, file_name)
	}
	return string(data[:])
}

write_status_line :: proc(
	mode: EditorMode,
	file_name: string,
	cursor: cursor.Cursor,
	#any_int scroll_amount: i32,
) -> string {
	file_name := shorten_file_name(file_name)
	defer delete(file_name)
	msg := strings.concatenate(
		{
			editor_mode_to_str(mode),
			" ",
			file_name,
			" ",
			fmt.tprint(cursor.y + scroll_amount, ":", cursor.x, sep = ""),
		},
	)
	log.info(msg)
	return msg
}
