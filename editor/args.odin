package editor

import "core:flags"
import "core:os"

Args_Info :: struct {
	file:     string `args:"pos=0,required" usage:"File for editing."`,
	log_file: os.Handle `args:"pos=1,name=log_file,file=wct,perms=0o644", usage:"File used for logging"`,
}

handle_args :: proc(args_info: ^Args_Info, args: []string) {
	flags.parse_or_exit(args_info, args)
}
