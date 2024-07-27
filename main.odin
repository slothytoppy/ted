package main

import "./editor"
import "core:log"
import "core:os"
import "deps/ncurses"
import "file_viewer"
import "viewport"

main :: proc() {
	/*
	editor.init_keyboard_poll()
	ncurses.initscr()
	ncurses.noecho()
	ncurses.raw()
	ncurses.keypad(ncurses.stdscr, true)
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	max_x, max_y: i32
	max_x = x
	max_y = y
	fv := file_viewer.InitFileViewer(
		viewport.Viewport{max_x = x, max_y = y, cursor = {cur_y = 0, cur_x = 0}},
	)
	//file_viewer.ReadDir(".", &fv)
	//file_viewer.render(fv, .render_whole)
	should_loop := true
	fd, _ := os.open("log", os.O_RDWR | os.O_TRUNC | os.O_CREATE, 0o644)
	context.logger = log.create_file_logger(fd)
  */
	renderer: editor.Renderer(editor.Editor)
	renderer.init = editor.default_init
	renderer.update = editor.default_updater
	renderer.render = editor.default_renderer
	editor.renderer_run(&renderer)
	/*
	for should_loop {
		event := editor.poll_keypress()
		if event.(editor.KeyboardEvent).key != "" {
			command := editor.update_file_viewer(&fv, event)
			fv.vp.max_y = cast(i32)len(fv.list) - 1
			log.info(command)
			if command == .quit {
				editor.deinit_editor()
				break
			}
			editor.render_file_viewer(fv, command)
		}
		/*
		switch ev in event {
		case events.KeyboardEvent:
			if ev.key == "" {
				continue
			}
			if ev.key == "^J" {
				fv = file_viewer.update(fv, .select)
				log.info("selected:", fv.selected_file.short_name)
			} else if ev.key == "KEY_UP" {
				fv = file_viewer.update(fv, .up)
				log.info("moved up to:", fv.vp.cursor.cur_y)
			} else if ev.key == "KEY_DOWN" {
				fv = file_viewer.update(fv, .down)
				log.info("moved down to:", fv.vp.cursor.cur_y)
			} else if ev.key == "control+q" {
				should_loop = false
				log.info("quiting")
			}
			file_viewer.render(fv, .update_cursor)
		}
    */
	}
  */
	//editor.run()
}
