package editor

import "../todin"
import "core:fmt"

STATUS_LINE_HEIGHT :: 1

@(private = "file")
STATUS_LINE_POSITION: int

set_status_line_position :: proc(#any_int line: int) {
	STATUS_LINE_POSITION = line
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
	return string(data[:]) if found else file_name
}

write_status_line :: proc(
	mode: EditorMode,
	file_name: string,
	cursor: Cursor,
	#any_int scroll_amount: i32,
) {
	todin.move(STATUS_LINE_POSITION, 0)
	todin.print(
		editor_mode_to_str(mode),
		shorten_file_name(file_name),
		fmt.tprint(cursor.y + scroll_amount, ":", cursor.x, sep = ""),
	)
}
