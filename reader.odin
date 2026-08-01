package po

import "core:fmt"
import "core:log"
import "core:os"
import "core:bufio"
import "core:strings"

Parser :: struct {
	prev_line: LineType,
	curr_line: LineType,
	curr_entry: POEntry,
	sb: strings.Builder,
	entries: [dynamic]POEntry,
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

line_type :: proc(line: string) -> (line_type: LineType, value: string) {
	splits, splits_err := strings.split_n(line, " ", 2)
	if splits_err != nil {
		fmt.println(splits_err)
	}
	log.debug(splits)

	current_token := splits[0]
	value = ""
	if len(splits) > 1 {
		value = splits[1]
	}

	switch current_token {
	case "":
		line_type = LineType.Blank
	case "#":
		line_type = LineType.TranslatorComment
	case "#.":
		line_type = LineType.ExtractedComment
	case "#:":
		line_type = LineType.Reference
	case "#,":
		line_type = LineType.Flag
	case "#|":
		line_type = LineType.PreviousMsgId
	case "msgid":
		line_type = LineType.MsgId
	case "msgstr":
		line_type = LineType.MsgStr
	case:
		if strings.starts_with(line, "\"") {
			line_type = LineType.Value
			value = line
		}
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

	current_line: int

	p := Parser{}

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

		ltype, lvalue := line_type(line)
		// log.debug("parsed line: ", ltype, strings.trim(lvalue, "\""))

		// we want to keep track of the real type of current "Value"
		if p.curr_line != .Value {
			p.prev_line = p.curr_line
		}
		p.curr_line = ltype

		#partial switch p.curr_line {
		case .Undefined, .Blank:
			// starting new entry
			if p.prev_line == .MsgStr {
				p.curr_entry.msgstr = strings.to_string(p.sb)
			}
			if p.curr_entry.msgid != "" && p.curr_entry.msgstr != "" {
				append(&p.entries, p.curr_entry)
			}
			p.curr_entry = POEntry{}
		case .MsgId:
			p.sb = strings.builder_make()
			strings.write_string(&p.sb, strings.trim(lvalue, "\""))
		case .MsgStr:
			p.curr_entry.msgid = strings.to_string(p.sb)

			p.sb = strings.builder_make()
			strings.write_string(&p.sb, strings.trim(lvalue, "\""))
		case .Value:
			strings.write_string(&p.sb, strings.trim(lvalue, "\""))
		case .Reference:
			ref_splits := strings.split(lvalue, " ")
			defer delete(ref_splits)

			for ref in ref_splits {
				append(&p.curr_entry.references, strings.clone(ref))
			}
			fmt.println(p.curr_entry.references)
		}
	}

	log.debug("parsed entries", p.entries)

	return list_to_return, ""
}

main :: proc() {
	context.logger = log.create_console_logger()
	parse_po_file("tests/short.po")
	// parse_po_file("tests/django.po")

	log.destroy_console_logger(context.logger)
}
