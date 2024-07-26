package file_viewer

import "../deps/ncurses"
import "../viewport"
import "core:log"
import "core:os"
import "core:strings"
import "core:testing"

Command :: enum {
	up,
	down,
	select,
	go_to_parent_dir,
	quit,
}

RendererEvent :: enum {
	render_whole,
	update_cursor,
}

FileList :: struct {
	short_name, full_name: string,
}

CurrentDir :: struct {
	path:   string,
	is_dir: bool,
}

FileViewer :: struct {
	list:          []FileList,
	selected_file: FileList,
	vp:            viewport.Viewport,
	current_dir:   CurrentDir,
}

@(require_results)
InitFileViewer :: proc(vp: viewport.Viewport) -> (fv: FileViewer) {
	fv.vp = vp
	return fv
}

ReadDir :: proc(path: string, file_viewer: ^FileViewer) {
	if dir_fd, err := os.open(path); err == os.ERROR_NONE {
		fis, r_err := os.read_dir(dir_fd, -1)
		if r_err == os.ERROR_NONE {
			new_path := ""
			if path == "" || path == "." {
				new_path = os.get_current_directory()
			} else {
				new_path = path
			}
			file_viewer.current_dir.path = new_path
			file_viewer.list = make([]FileList, len(fis))
			for fi, i in fis {
				file_viewer.list[i].short_name = fi.name
				file_viewer.list[i].full_name = fi.fullpath
			}
		}
	}
}

go_to_parent_dir :: proc(file_viewer: FileViewer) -> (fv: FileViewer) {
	curr_dir := file_viewer.current_dir.path
	log.info(curr_dir)
	fv = file_viewer
	if curr_dir == "." {
		curr_dir = os.get_current_directory()
	}
	#reverse for r, i in curr_dir {
		if r == '/' {
			// so that i go to the next / if the path starts with a /
			if i != len(curr_dir) {
				curr_dir = curr_dir[:i]
				break
			}
		}
	}
	ReadDir(curr_dir, &fv)
	return fv
}

go_to_child_dir :: proc(file_viewer: FileViewer, path: string) -> (fv: FileViewer) {
	fv = file_viewer
	is_relative: bool = true
	if path[0] == '/' {
		is_relative = false
	}
	current_dir := fv.current_dir.path
	fv.current_dir.path = strings.concatenate({current_dir, "/", path}, context.temp_allocator)
	if os.is_dir(fv.selected_file.full_name) {
		ReadDir(fv.current_dir.path, &fv)
		fv.current_dir.is_dir = true
	}
	return fv
}

get_selected :: proc(file_viewer: FileViewer) -> FileList {
	idx := min(file_viewer.vp.cursor.cur_y, cast(i32)len(file_viewer.list))
	return {
		short_name = file_viewer.list[idx].short_name,
		full_name = file_viewer.list[idx].full_name,
	}
}

update :: proc(file_viewer: FileViewer, command: Command) -> FileViewer {
	new_file_viewer := file_viewer
	switch command {
	case .up:
		new_file_viewer.vp.cursor.cur_y -= 1
	case .down:
		new_file_viewer.vp.cursor.cur_y += 1
	case .select:
		new_file_viewer.selected_file = get_selected(new_file_viewer)
		log.info(new_file_viewer.selected_file)
		new_file_viewer = go_to_child_dir(
			new_file_viewer,
			new_file_viewer.selected_file.short_name,
		)
	case .go_to_parent_dir:
		new_file_viewer = go_to_parent_dir(new_file_viewer)
		log.info(new_file_viewer.current_dir, new_file_viewer.selected_file)
	case .quit:
	}
	return new_file_viewer
}

render :: proc(file_viewer: FileViewer, event: RendererEvent) {
	switch event {
	case .render_whole:
		ncurses.erase()
		ncurses.refresh()
		for entry, i in file_viewer.list {
			ncurses.mvprintw(
				cast(i32)i,
				0,
				"%s",
				strings.clone_to_cstring(entry.short_name, context.temp_allocator),
			)
			ncurses.move(file_viewer.vp.cursor.cur_y, file_viewer.vp.cursor.cur_x)
		}
	case .update_cursor:
		ncurses.move(file_viewer.vp.cursor.cur_y, file_viewer.vp.cursor.cur_x)
	}
	ncurses.refresh()
}
