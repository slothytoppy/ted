package todin

import "core:fmt"
import "core:log"
import "core:os"
import "core:testing"
import "core:unicode/utf8"

EscapeKey :: struct {}
FunctionKey :: struct {}
Resize :: struct {
	new_cols, new_rows: i32,
}

Nothing :: struct {}
Enter :: struct {}

Event :: union {
	Nothing,
	Enter,
	Key,
	ArrowKey,
	EscapeKey,
	FunctionKey,
	BackSpace,
	Resize,
}

Key :: struct {
	keyname: rune,
	control: bool,
}

BackSpace :: struct {}

ArrowKey :: enum {
	up,
	down,
	left,
	right,
}

@(private = "file")
MachineState :: enum {
	initial,
	normal,
	csi,
	escape,
	backspace,
}

read :: proc() -> Event {
	if has_resized() {
		log.debug("resize")
		return Resize{GLOBAL_WINDOW_SIZE.cols, GLOBAL_WINDOW_SIZE.rows}
	}
	data: [512]byte
	bytes_read, err := os.read(os.stdin, data[:])
	if bytes_read <= 0 || err != os.ERROR_NONE {
		return nil
	}
	key := utf8.string_to_runes(string(data[:bytes_read]))
	defer delete(key)
	event := parse(key)
	return event
}

/* 
state graph:
  initial_state->normal, control, or escape
  normal->normal 
  control->control, control->arrow_key 
  escape->escape
*/


// parses a slice of runes using ansi parsing, returns an Event
@(private = "file")
parse :: proc(key: []rune) -> Event {
	state := MachineState.initial
	event: Event
	loop: for b in key {
		switch state {
		case .initial:
			event, state = initial_state(b, state)
		case .normal:
			event, state = normal_state(b)
		case .csi:
			event, state = control_state(b)
		case .escape:
			event, state = escape_state(b, state)
		case .backspace:
			event, state = backspace_state(b)
		}
	}
	log.debug(event, state)
	return event
}

@(private = "file")
initial_state :: proc(datum: rune, state: MachineState) -> (Event, MachineState) {
	switch datum {
	case 13:
		return Enter{}, .initial
	case 1 ..= 26:
		return control_state(datum)
	case 27:
		return escape_state(datum, .escape)
	case 127:
		return backspace_state(datum)
	case 32 ..= 126:
		return normal_state(datum)
	case:
		return nil, .initial
	}
}

@(private = "file")
normal_state :: proc(datum: rune) -> (Event, MachineState) {
	switch datum {
	case 32 ..= 126:
		return Key{datum, false}, .normal
	case:
		return nil, .initial
	}
}

@(private = "file")
backspace_state :: proc(datum: rune) -> (Event, MachineState) {
	switch datum {
	case 127:
		return BackSpace{}, .backspace
	case:
		return nil, .initial
	}
}

@(private = "file")
control_state :: proc(datum: rune) -> (Event, MachineState) {
	log.debug(transmute([]byte)utf8.runes_to_string({datum}))
	switch datum {
	case 1 ..= 26:
		return Key{keyname = datum + 96, control = true}, .csi
	case:
		return nil, .initial
	}
}

@(private = "file")
escape_state :: proc(datum: rune, state: MachineState) -> (Event, MachineState) {
	log.debug(int(datum), state)
	switch datum {
	case 27:
		return EscapeKey{}, .escape
	case 91:
		return nil, .escape
	case 65:
		return .up, .escape
	case 66:
		return .down, .escape
	case 67:
		return .right, .escape
	case 68:
		return .left, .escape
	case:
		return nil, .initial
	}
}

event_to_string :: proc(event: Event) -> string {
	switch e in event {
	case Enter:
		return "enter"
	case Nothing:
		return ""
	case ArrowKey:
		switch e {
		case .up:
			return "up"
		case .down:
			return "down"
		case .left:
			return "left"
		case .right:
			return "right"
		}
	case EscapeKey:
		return "escape"
	case FunctionKey:
	case BackSpace:
		return "backspace"
	case Key:
		if e.control {
			if e.keyname == 'm' {
				return "enter"
			}
			return fmt.tprintf("<c-%c>", e.keyname)
		}
		return fmt.tprint(e.keyname)
	case Resize:
		return "resize"
	}
	return ""
}

@(test)
test_normal_key :: proc(t: ^testing.T) {
	data := []rune{'A'}
	expected := Key{'A', false}
	result := parse(data)
	testing.expect(t, result == expected)
}

@(test)
test_control_key :: proc(t: ^testing.T) {
	data := []rune{1}
	expected := Key{97, true}
	result := parse(data)
	testing.expect_value(t, result, expected)
}

@(test)
test_arrow_key :: proc(t: ^testing.T) {
	data := []rune{27, 91, 65}
	expected := ArrowKey{}
	result := parse(data)
	testing.expect_value(t, result, expected)
}

@(test)
test_key_to_string :: proc(t: ^testing.T) {
	key := []rune{65}
	expected := "A"
	result := event_to_string(parse(key))
	testing.expect_value(t, result, expected)
}
