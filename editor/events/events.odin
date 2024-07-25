package events

Event :: union {
	KeyboardEvent,
}

GetEvent :: proc(event: Event) -> Event {
	switch e in event {
	case KeyboardEvent:
	}
	return event.(KeyboardEvent)
}
