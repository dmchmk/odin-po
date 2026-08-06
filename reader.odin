package po

import "core:fmt"
import "core:log"
import "core:os"
import "core:bufio"
import "core:strings"

Parser :: struct {
	prev_line_type: LineType,
	curr_line_type: LineType,
	curr_line_number: int,
	curr_entry: POEntry,
	sb: strings.Builder,
}

Error :: enum {
	None,
	OpenFileError,
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


parse_po_file :: proc(po_file: ^POFile) -> Error {
	f, ferr := os.open(po_file.pofile)
	if ferr != nil {
		return .OpenFileError
	}
	defer os.close(f)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.to_stream(f), buffer[:])
	defer bufio.reader_destroy(&r)

	p := new(Parser)
	defer free(p)

	for {
		raw_line, err := bufio.reader_read_string(&r, '\n', context.allocator)
		if err != nil {
			break
		}
		defer delete(raw_line, context.allocator)

		p.curr_line_number += 1
		line := strings.trim_right(raw_line, "\r\n")

		BOM :: "\ufeff"
		if p.curr_line_number == 1 && strings.starts_with(line, BOM) {
			line = line[len(BOM):]
		}

		ltype, lvalue := line_type(line)

		// we want to keep track of the real type of current "Value"
		if p.curr_line_type != .Value {
			p.prev_line_type = p.curr_line_type
		}
		p.curr_line_type = ltype

		#partial switch p.curr_line_type {
		case .Undefined, .Blank:
			// starting new entry
			if p.prev_line_type == .MsgStr {
				p.curr_entry.msgstr = strings.to_string(p.sb)
			}

			if p.prev_line_type == .Blank {
				continue
			}

			// if first one is metadata, parse accordingly
			if len(&po_file.entries) == 0 && p.curr_entry.msgid == "" {
				metadata_lines := strings.split(p.curr_entry.msgstr, "\\n")
				defer delete(metadata_lines)

				for mline in metadata_lines {
					ml_kv := strings.split_n(mline, ": ", 2)
					if len(ml_kv) > 1 {
						po_file.metadata[ml_kv[0]] = ml_kv[1]
					}
				}
			// else append to entries
			} else {
				append(&po_file.entries, p.curr_entry)
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
		}
	}

	return .None
}

main :: proc() {
	context.logger = log.create_console_logger()

	// on later stages we'll be able to also pass pofile as plain text
	po_file := POFile{pofile= "tests/short.po"}
	parse_po_file(&po_file)
	log.debug(po_file)
	// parse_po_file("tests/django.po")

	log.destroy_console_logger(context.logger)
}
