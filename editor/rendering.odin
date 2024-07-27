package editor

import "../buffer"
import "core:strings"

Renderer :: struct($T: typeid) {
	data:   T,
	init:   proc() -> T,
	update: proc(model: ^T, event: Event) -> Event,
	render: proc(model: T) -> []string,
}

default_init :: proc() -> Editor {
	editor: Editor = init_editor()
	return editor
}

default_updater :: proc(editor: ^Editor, editor_event: Event) -> (event: Event) {
	switch e in editor_event {
	case Init:
		editor^ = default_init()
		event = Init{}
		log("init")
	case KeyboardEvent:
		if e.key == "control+q" {
			event = Quit{}
		} else if e.key != "" {
			event = e
		}
	case Quit:
		event = Quit{}
	case GoToLineStart:
		unimplemented()
	case GoToLineEnd:
		unimplemented()
	}
	return event
}

default_renderer :: proc(editor: Editor) -> []string {
	log("called renderer")
	strs := make([]string, len(editor.buffer))
	for line, i in editor.buffer {
		strs[i] = transmute(string)line[:]
	}
	return strs
}
