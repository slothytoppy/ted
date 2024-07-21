package editor

import "core:flags"
import "core:fmt"
import "core:os"

Args_Info :: struct {
	file:     string `args:"pos=0,required" usage:"File for editing"`,
	log_file: os.Handle `args:"pos=1,file=cwt,perms=0644,name=log_file" usage:"optional file for logging"`,
}

parse_cli_arguments :: proc(arg_info: ^Args_Info) {
	// ignores first cli argument which is path_to_exe
	args: []string = os.args
	// what flags.parse_or_exit does but i have to do this myself
	if len(os.args) > 1 {
		args = args[1:]
	}
	error := flags.parse(arg_info, args)
	switch specific_error in error {
	case flags.Parse_Error:
		fmt.println("parsing error")
	case flags.Open_File_Error:
		fmt.println("open file error")
	case flags.Validation_Error:
		if arg_info.file == "" {
			fmt.println("empty")
		}
		fmt.println("validation error")
	case flags.Help_Request:
		fmt.println("help request")
	}
	fmt.print(error, args)
}
