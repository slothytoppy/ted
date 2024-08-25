package editor

import "../todin"

COMMAND_LINE_HEIGHT :: 1
COMMAND_LINE_POSITION: int

@(private = "file")
internal_buffer: Line
@(private = "file")
internal_cursor: Cursor

set_command_line_position :: proc(#any_int line: int) {
	COMMAND_LINE_POSITION = line
}

write_rune_to_command_line :: proc(r: rune) {
	append(&internal_buffer, Cell{0, 0, todin.Key{r, false}})
	internal_cursor.x += 1
}

remove_char_from_command_line :: proc() {
	delete_char(&internal_buffer, Cursor{x = cast(i32)internal_cursor.x})
	internal_cursor.x -= 1
}

print_command_line :: proc() {
	todin.move(COMMAND_LINE_POSITION, 0)
	for cell in internal_buffer {
		todin.print(cell.datum.keyname)
	}
}

Commands :: enum {
	quit,
	save,
	save_as,
	edit_file,
}

ListOfCommands: [Commands]string

check_command :: proc() {
	defer clear(&internal_buffer)
}
