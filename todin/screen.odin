package todin

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "core:testing"

// each buffer has to emulate the real screen ie, only say 48*105 or 48 cols and 105 rows
@(private = "file")
Line :: [dynamic]rune

@(private = "file")
Position :: struct {
	y, x: u16,
}

@(private = "file")
DoubleBuffer :: struct {
	front_buffer, back_buffer: [dynamic]Line,
	screen_size:               Position,
	pos:                       Position,
	displayed, updated:        u8,
}

@(private = "file")
internal_double_buffer := DoubleBuffer{}
@(init)
double_buffer_init :: proc() {
	internal_double_buffer.screen_size.y = cast(u16)get_max_cols()
	internal_double_buffer.screen_size.x = cast(u16)get_max_rows()
	reserve(
		&internal_double_buffer.front_buffer,
		internal_double_buffer.screen_size.y * internal_double_buffer.screen_size.x,
	)
	reserve(
		&internal_double_buffer.back_buffer,
		internal_double_buffer.screen_size.y * internal_double_buffer.screen_size.x,
	)
	inject_at(
		&internal_double_buffer.back_buffer,
		cast(int)internal_double_buffer.screen_size.y,
		Line{},
	)
	inject_at(
		&internal_double_buffer.front_buffer,
		cast(int)internal_double_buffer.screen_size.y,
		Line{},
	)
}

enter_alternate_screen :: proc() {
	os.write_string(os.stdin, "\e[?1049h")
	clear_screen()
	reset_cursor()
}

leave_alternate_screen :: proc() {
	os.write_string(os.stdin, "\e[?1049l")
}

clear_screen :: proc() {
	os.write_string(os.stdin, "\e[2J")
}

delete_line :: proc() {
	os.write_string(os.stdin, "\e[2K")
}

move_print :: proc(y, x: int, args: ..any) {
	move(y, x)
	print(..args)
}

print :: proc(args: ..any) {
	os.write_string(os.stdin, fmt.tprint(..args))
}

delch :: proc() {
	os.write_string(os.stdin, "\e[1P")
}

@(private = "file")
get_line_len :: proc() -> i32 {
	return cast(i32)len(internal_double_buffer.front_buffer[internal_double_buffer.pos.y])
}

write :: proc(data: ..rune) {
	if cast(u16)len(internal_double_buffer.front_buffer) < internal_double_buffer.pos.y {
		inject_at(
			&internal_double_buffer.front_buffer,
			cast(int)internal_double_buffer.pos.y,
			Line{},
		)
	}
	append(&internal_double_buffer.front_buffer[internal_double_buffer.pos.y], ..data)
}

@(test)
test_init_double_buffer :: proc(t: ^testing.T) {
	testing.expect_value(t, internal_double_buffer.screen_size.y, 48)
	write('a', 'b', 'c', 'd')
	log.info(internal_double_buffer)
}
