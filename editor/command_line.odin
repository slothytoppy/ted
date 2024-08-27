package editor

import "../todin"
import "core:log"
import "core:strings"

COMMAND_LINE_HEIGHT :: 1
COMMAND_LINE_POSITION: int

Save :: struct {}
SaveAs :: struct {
	file_name: string,
}
EditFile :: struct {
	file_name: string,
}

Commands :: union {
	Quit,
	Save,
	SaveAs,
	EditFile,
}

@(private = "file")
internal_buffer: Line
@(private = "file")
internal_cursor: Cursor

// this is kinda meh
set_command_line_position :: proc(#any_int line: int) {
	COMMAND_LINE_POSITION = line
}

write_rune_to_command_line :: proc(r: rune) {
	append(&internal_buffer, Cell{0, 0, byte(r)})
	internal_cursor.x += 1
}

write_string_to_command_line :: proc(s: string) {
	for r in s {
		write_rune_to_command_line(r)
	}
}

remove_char_from_command_line :: proc() {
	delete_char(&internal_buffer, Cursor{x = cast(i32)internal_cursor.x})
	internal_cursor.x -= 1
}

print_command_line :: proc() {
	todin.move(COMMAND_LINE_POSITION, 0)
	todin.print(':')
	tmp: [dynamic]byte
	defer delete(tmp)
	for cell in internal_buffer {
		append(&tmp, cell.datum)
	}
	todin.print(string(tmp[:]))
	log.info(string(tmp[:]))
	todin.move(COMMAND_LINE_POSITION, internal_cursor.x + 2)
}

@(require_results)
check_command :: proc() -> Maybe(Commands) {
	line := line_to_string(internal_buffer)
	if len(internal_buffer) <= 0 || line == "" {
		return nil
	}
	defer delete(line)
	defer delete_line(&internal_buffer)
	defer internal_cursor.x = 0

	switch line[0] {
	case 'q':
		return Quit{}
	case 'w':
		if len(line) == 1 {
			return Save{}
		}
		res := strings.split(line, " ")
		if len(res) >= 2 {
			return SaveAs{res[1]}
		}
	case 'e':
		res := strings.split(line, " ")
		if len(res) == 1 {
			return nil
		}
		if len(res) >= 2 {
			return EditFile{strings.clone(res[1])}
		}
	}
	return nil
}
