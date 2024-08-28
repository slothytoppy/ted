package editor

import "../todin"
import "core:log"
import "core:strings"

COMMAND_LINE_HEIGHT :: 1

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

CliEvent :: union {
	ErrorMsg,
	Commands,
}

ErrorMsg :: string

CommandLine :: struct {
	data:   Line,
	error:  Line,
	cursor: Cursor,
}

// this is kinda meh
set_command_line_position :: proc(cli: ^CommandLine, #any_int line: i32) {
	cli.cursor.y = line
}

write_rune_to_command_line :: proc(cli: ^CommandLine, r: rune) {
	append(&cli.data, Cell{0, 0, byte(r)})
	cli.cursor.x += 1
}

write_string_to_command_line :: proc(cli: ^CommandLine, s: string) {
	for r in s {
		write_rune_to_command_line(cli, r)
	}
}

write_error_to_command_line :: proc(cli: ^CommandLine, s: string) {
	for r in s {
		append(&cli.error, Cell{0, 0, byte(r)})
	}
	cli.cursor.x = 0
}

remove_char_from_command_line :: proc(cli: ^CommandLine) {
	delete_char(&cli.data, Cursor{x = cast(i32)cli.cursor.x})
	cli.cursor.x -= 1
}

print_command_line :: proc(cli: CommandLine) {
	todin.move(cli.cursor.y, 0)
	if len(cli.error) > 0 {
		render_buffer_line(cli.error, {max_x = 1000}, 0)
		return
	}
	todin.print(':')
	tmp: [dynamic]byte
	defer delete(tmp)
	for cell in cli.data {
		append(&tmp, cell.datum)
	}
	todin.print(string(tmp[:]))
	log.info(string(tmp[:]))
	todin.move(cli.cursor.y, cli.cursor.x + 2)
}

/* 

  `:e` <path> 
  what if path doesnt exist or you do only `:e`?
  i need to give the user an error somehow

*/

@(require_results)
check_command :: proc(cli: ^CommandLine) -> (event: CliEvent) {
	line := line_to_string(cli.data)
	defer delete(line)
	defer delete_line(&cli.data)
	defer cli.cursor.x = 0

	command: Commands

	if len(line) <= 0 {
		return
	}
	switch line[0] {
	case 'q':
		command = Quit{}
	case 'w':
		if len(line) == 1 {
			command = Save{}
		}
		res := strings.split(line, " ")
		if len(res) >= 2 {
			command = SaveAs{res[1]}
		}
	case 'e':
		res := strings.split(line, " ")
		if len(res) == 1 {
			write_error_to_command_line(cli, "ERROR: use `:e` <path>")
		}
		if len(res) >= 2 {
			command = EditFile{strings.clone(res[1])}
		}
	}
	return command
}
