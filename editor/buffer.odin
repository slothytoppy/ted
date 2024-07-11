package editor_buffer

import "core:strings"

Buffer :: struct {
	data: [dynamic]strings.Builder,
}

Mode :: enum {
	normal,
	insert,
	search,
	command,
}

Editor_State :: struct {
	buffer:  Buffer,
	mode:    Mode,
	running: bool,
}
