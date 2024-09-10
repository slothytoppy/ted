package editor

import "../todin"
import "buffer"
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
	data:     buffer.Line,
	error:    buffer.Line,
	cursor:   Cursor,
	position: i32,
}

set_command_line_position :: proc(cli: ^CommandLine, #any_int line: i32) {
	cli.position = line
}

write_rune_to_command_line :: proc(cli: ^CommandLine, r: rune) {
	append(&cli.data, buffer.Cell{r})
	cli.cursor.x += 1
}

write_string_to_command_line :: proc(cli: ^CommandLine, s: string) {
	for r in s {
		write_rune_to_command_line(cli, r)
	}
}

write_error_to_command_line :: proc(cli: ^CommandLine, s: string) {
	for r in s {
		append(&cli.data, buffer.Cell{r})
	}
	cli.cursor.x = 0
}

remove_char_from_command_line :: proc(cli: ^CommandLine) {
	if len(cli.data) <= 0 {
		return
	}
	cli.cursor.x = saturating_sub(cli.cursor.x, 1, 0)
	ordered_remove(&cli.data, cli.cursor.x)
}

print_command_line :: proc(cli: CommandLine) -> string {
	msg: [dynamic]byte
	append(&msg, buffer.line_to_string(cli.data))
	return string(msg[:])
}

clear_command_line :: proc(cli: ^CommandLine) {
	if len(cli.data) >= 1 {
		clear(&cli.data)
		cli.cursor.x = 0
	}
}

@(require_results)
check_command :: proc(cli: ^CommandLine) -> (event: CliEvent) {
	if len(cli.data) <= 0 {
		return
	}

	line := buffer.line_to_string(cli.data)
	defer delete(line)
	defer clear_command_line(cli)

	command: Commands

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
