package main

import "./editor"
import "core:flags"
import "core:os"

main :: proc() {
	arg_info: editor.Args_Info
	error := editor.parse_cli_arguments(&arg_info)
	switch e in error {
	case editor.EditorError:
		switch e {
		case .file_doesnt_exist, .no_file, .none:
		}
	case flags.Error:
		switch error in e {
		case flags.Parse_Error, flags.Help_Request, flags.Open_File_Error, flags.Validation_Error:
			editor.print_error(error)
			os.exit(1)
		}
	}
	context.logger = editor.init_logger_from_fd(arg_info.log_file)
	editor.run(arg_info.file)
}
