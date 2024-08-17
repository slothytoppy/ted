package editor

import "core:flags"
import "core:fmt"
import "core:os"

Args_Info :: struct {
	file:     string `args:"pos=0" usage:"File for editing"`,
	log_file: os.Handle `args:"pos=1,file=cwt,perms=0644,name=log_file" usage:"optional file for logging"`,
	position: int `args:"name=pos" usage:"start editing at line <num>"`,
}

EditorError :: enum {
	none,
	no_file,
	file_doesnt_exist,
}

Error :: union {
	EditorError,
	flags.Error,
}

@(require_results)
parse_cli_arguments :: proc(arg_info: ^Args_Info) -> Error {
	// ignores first cli argument which is path_to_exe
	args: []string = os.args
	flags_error: flags.Error
	// what flags.parse_or_exit does but i have to do this myself
	if len(os.args) == 1 {
		return .no_file
	}
	if len(os.args) > 1 {
		args = args[1:]
	}
	error := flags.parse(arg_info, args)
	switch specific_error in error {
	case flags.Parse_Error, flags.Open_File_Error, flags.Help_Request:
		return specific_error
	case flags.Validation_Error:
		flags_error = specific_error
		return flags_error
	}
	switch arg_info.file {
	case "":
		return .file_doesnt_exist
	case:
		if !os.exists(arg_info.file) {
			return .file_doesnt_exist
		}
		return .none
	}
	return nil
}

print_error :: proc(error: flags.Error) {
	flags.print_errors(Args_Info, error, "todin")
}
