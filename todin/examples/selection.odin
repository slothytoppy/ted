package selection

import todin "../"
import "core:log"
import "core:os"

State :: struct {
	choices:      []string,
	cursor:       i32,
	should_quit:  bool,
	has_selected: bool,
}

main :: proc() {
	fd, _ := os.open("log", os.O_RDWR | os.O_TRUNC | os.O_CREATE, 0o644)
	context.logger = log.create_file_logger(fd)
	todin.init()
	todin.enter_alternate_screen()
	state: State
	state.choices = {"hello", "goodbye"}
	view(state)
	event_loop: for {
		can_read := todin.poll()
		if !can_read {
			continue
		}
		event := todin.read()
		switch todin.event_to_string(event) {
		case "resize":
			log.info(event)
			break event_loop
		}
		has_event := update(event, &state)
		view(state)
		if has_event == true {
			if state.should_quit == true {
				break event_loop
			}
		}
	}
	todin.leave_alternate_screen()
	todin.deinit()
}

update :: proc(event: todin.Event, state: ^State) -> bool {
	has_event := false
	#partial switch e in event {
	case:
		switch todin.event_to_string(e) {
		case "up":
			state.cursor = saturating_sub(state.cursor, 1, 0)
			if state.has_selected {
				state.cursor = saturating_sub(state.cursor, 1, 0)
			}
			has_event = true
			state.has_selected = false
		case "down":
			state.cursor = saturating_add(state.cursor, 1, cast(i32)len(state.choices) - 1)
			has_event = true
			state.has_selected = false
		case "enter":
			todin.clear_screen()
			todin.reset_cursor()
			assert(state.cursor < cast(i32)len(state.choices))
			todin.print("selected:", state.choices[state.cursor])
			log.info("cursor:", state.cursor)
			state.has_selected = true
			has_event = true
		case "<c-q>":
			state.should_quit = true
			has_event = true
		}
	}

	return has_event
}

view :: proc(state: State) {
	if state.has_selected {
		return
	}
	todin.reset_cursor()
	todin.clear_screen()
	for str in state.choices {
		todin.print(str)
		todin.move_to_start_of_next_line()
	}
	todin.move(state.cursor + 1, 0)
}

saturating_add :: proc(#any_int val, amount, max: i32) -> i32 {
	if val + amount < max {
		log.info("add:", val + amount, max)
		return val + amount
	}
	log.info("add:", val, amount, max)
	return max
}

saturating_sub :: proc(#any_int val, amount, min: i32) -> i32 {
	if val - amount > min {
		log.info("sub:", val - amount, min)
		return val - amount
	}
	log.info("sub:", val, amount, min)
	return min
}
