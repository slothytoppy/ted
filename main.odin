package main

import "./editor"

main :: proc() {
	renderer: editor.Renderer(editor.Editor)
	renderer.init = editor.default_init
	renderer.update = editor.default_updater
	renderer.render = editor.default_renderer
	renderer.data = editor.default_init()
	editor.renderer_run(&renderer)
}
