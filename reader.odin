package po

import "core:fmt"
import "core:log"
import "core:os"
import "core:bufio"
import "core:strings"

State :: enum {
	LookingForEntry,
	InHeader,
	InMsgId,
	InMsgStr,
	InMsgCtxt,
}

LineType :: enum {
	Undefined,
	Blank,
	TranslatorComment,
	ExtractedComment,
	Reference,
	Flag,
	PreviousMsgId,
	MsgId,
	MsgStr,
	Value,
}

line_type :: proc(line: string) -> (result: LineType) {
	splits, splits_err := strings.split_n(line, " ", 2)
	if splits_err != nil {
		fmt.println(splits_err)
	}
	log.debug(splits)

	current_token := splits[0]

	switch current_token {
	case "":
		result = LineType.Blank
	case "#":
		result = LineType.TranslatorComment
	case "#.":
		result = LineType.ExtractedComment
	case "#:":
		result = LineType.Reference
	case "#,":
		result = LineType.Flag
	case "#|":
		result = LineType.PreviousMsgId
	case "msgid":
		result = LineType.MsgId
	case "msgstr":
		result = LineType.MsgStr
	case:
		result = LineType.Value
	}

	delete(splits)
	return

}


parse_po_file :: proc(file_path: string) -> (result: []POEntry, err: string) {
	list_to_return: []POEntry

	f, ferr := os.open(file_path)
	if ferr != nil {
		return nil, fmt.tprintf("%s", ferr)
	}
	defer os.close(f)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.to_stream(f), buffer[:])
	defer bufio.reader_destroy(&r)

	current_state: State
	current_entry: POEntry
	current_line: int

	for {
		raw_line, err := bufio.reader_read_string(&r, '\n', context.allocator)
		if err != nil {
			break
		}
		defer delete(raw_line, context.allocator)

		current_line += 1
		line := strings.trim_right(raw_line, "\r\n")

		BOM :: "\ufeff"
		if current_line == 1 && strings.starts_with(line, BOM) {
			line = line[len(BOM):]
		}

		// switch (current_state, line_type(line)) {
		// case (.LookingForEntry, "msgstr")
		// }

		log.debug("line type:", line_type(line))
	}

	return list_to_return, ""
}

main :: proc() {
	context.logger = log.create_console_logger()
	parse_po_file("tests/feff1.po")
	// parse_po_file("tests/django.po")

	log.destroy_console_logger(context.logger)
}
