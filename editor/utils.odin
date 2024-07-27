package editor

import "core:log"
import "core:os"

read_file :: proc(path: string) -> []byte {
	data, err := os.read_entire_file_from_filename(path)
	if err != true {
		return {}
	}
	return data
}

logger_init :: proc(log_file: string) -> (logger: log.Logger, result: bool) {
	fd, err := os.open(log_file, os.O_CREATE | os.O_WRONLY, 0o644)
	if err != os.ERROR_NONE {
		return {}, false
	}
	logger = log.create_file_logger(fd)
	return logger, true
}

log :: proc(args: ..any, loc := #caller_location) {
	log.info(args, location = loc)
}
