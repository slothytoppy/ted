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

FileViewer :: struct {
	list:          []FileList,
	selected_file: FileList,
	current_dir:   string,
	vp:            viewport.Viewport,
}

@(require_results)
InitFileViewer :: proc(path: string, vp: viewport.Viewport) -> (fv: FileViewer) {
	ReadDir(path, &fv)
	fv.vp = vp
	return fv
}

ReadDir :: proc(path: string, file_viewer: ^FileViewer) {
	if dir_fd, err := os.open(path); err == os.ERROR_NONE {
		fis, r_err := os.read_dir(dir_fd, -1)
		if r_err == os.ERROR_NONE {
			file_viewer.current_dir = path
			file_viewer.list = make([]FileList, len(fis))
			for fi, i in fis {
				file_viewer.list[i].short_name = fi.name
				file_viewer.list[i].full_name = fi.fullpath
			}
		}
		delete(fis)
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
		idx := min(new_file_viewer.vp.cursor.cur_y, cast(i32)len(new_file_viewer.list))
		new_file_viewer.selected_file = new_file_viewer.list[idx]
		log.info(new_file_viewer.selected_file, idx)
		new_file_viewer = go_to_child_dir(
			new_file_viewer,
			new_file_viewer.selected_file.short_name,
		)
	case .go_to_parent_dir:
		new_file_viewer = go_to_parent_dir(new_file_viewer)
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

go_to_parent_dir :: proc(file_viewer: FileViewer) -> (fv: FileViewer) {
	curr_dir := file_viewer.current_dir
	if curr_dir == "/" {
		return file_viewer
	}
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
	delete(curr_dir)
	return fv
}

go_to_child_dir :: proc(file_viewer: FileViewer, path: string) -> (fv: FileViewer) {
	fv = file_viewer
	current_dir := file_viewer.current_dir
	if current_dir == "." {
		current_dir = os.get_current_directory()
	}
	fv.current_dir = strings.concatenate({current_dir, "/", path}, context.temp_allocator)
	if os.is_dir(fv.current_dir) {
		ReadDir(fv.current_dir, &fv)
	}
	return fv
}

@(test)
parent_dir_test :: proc(t: ^testing.T) {
	file_viewer: FileViewer
	ReadDir(".", &file_viewer)
	file_viewer = go_to_parent_dir(file_viewer)
	log.info(file_viewer.current_dir)
}

@(test)
child_dir_test :: proc(t: ^testing.T) {
	file_viewer: FileViewer
	ReadDir(".", &file_viewer)
	file_viewer = go_to_child_dir(file_viewer, file_viewer.list[0].short_name)
	log.info(file_viewer.current_dir)
}
