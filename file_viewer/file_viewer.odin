package file_viewer

import "../deps/ncurses"
import "core:os"

Cursor :: struct {
	cur_x, cur_y, max_x, max_y: i32,
}

FileList :: struct {
	short_name, full_name: string,
}

FileViewer :: struct {
	using _: Cursor,
	list:    []FileList,
}

InitFileViewer :: proc(#any_int cur_x, cur_y, max_x, max_y: i32) -> FileViewer {
	return FileViewer{cur_x = cur_x, cur_y = cur_y, max_x = max_x, max_y = max_y}
}

ReadDir :: proc(path: string, file_viewer: ^FileViewer) {
	if dir_fd, err := os.open(path); err == os.ERROR_NONE {
		fis, r_err := os.read_dir(dir_fd, -1)
		if r_err == os.ERROR_NONE {
			file_viewer.list = make([]FileList, len(fis))
			for fi, i in fis {
				file_viewer.list[i].short_name = fi.name
				file_viewer.list[i].full_name = fi.fullpath
			}
		}
	}
}

render :: proc() {
	ncurses.printw("")
}
