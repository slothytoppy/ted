package main

import "./editor"
import "./editor/events"

main :: proc() {
	renderer: events.Renderer(editor.Editor)
	renderer.init = editor.default_init
	renderer.update = editor.default_updater
	renderer.render = editor.default_renderer
	editor.run(&renderer)
}
