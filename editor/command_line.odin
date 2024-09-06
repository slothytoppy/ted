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
	data:     buffer.Buffer,
	error:    buffer.Buffer,
	cursor:   Cursor,
	position: i32,
}

// this is kinda meh
set_command_line_position :: proc(cli: ^CommandLine, #any_int line: i32) {
	cli.position = line
}

write_rune_to_command_line :: proc(cli: ^CommandLine, r: rune) {
	if len(cli.data) <= 0 {
		append(&cli.data, buffer.Line{})
	}
	append_rune(&cli.data, cli.cursor, r)
	cli.cursor.x += 1
}

write_string_to_command_line :: proc(cli: ^CommandLine, s: string) {
	for r in s {
		write_rune_to_command_line(cli, r)
	}
}

write_error_to_command_line :: proc(cli: ^CommandLine, s: string) {
	for r in s {
		append(&cli.error[0], buffer.Cell{0, 0, r})
	}
	cli.cursor.x = 0
}

remove_char_from_command_line :: proc(cli: ^CommandLine) {
	if len(cli.data) <= 0 {
		return
	}
	remove_rune(&cli.data, cli.cursor)
	cli.cursor.x = saturating_sub(cli.cursor.x, 1, 0)
}

print_command_line :: proc(cli: CommandLine) {
	if len(cli.data) <= 0 || len(cli.data[0]) <= 0 {
		return
	}
	if len(cli.error) > 0 {
		render_buffer_with_scroll(cli.error, {max_y = cli.position, max_x = 1000})
		return
	}
	todin.move(cli.position + 1, 0)
	todin.print(':')
	tmp: [dynamic]byte
	defer delete(tmp)
	for line in cli.data {
		for cell in line {
			append(&tmp, byte(cell.datum))
		}
	}
	todin.print(string(tmp[:]))
	log.debug(string(tmp[:]))
	todin.move_right()
}

clear_command_line :: proc(cli: ^CommandLine) {
	if len(cli.data) >= 1 {
		clear(&cli.data[0])
		cli.cursor.x = 0
	}
}

@(require_results)
check_command :: proc(cli: ^CommandLine) -> (event: CliEvent) {
	if len(cli.data) <= 0 || len(cli.data[0]) <= 0 {
		return
	}

	line := buffer.line_to_string(cli.data[0])
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
