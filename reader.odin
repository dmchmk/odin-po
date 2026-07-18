package po

import "core:fmt"
import "core:os"
import "core:bufio"
import "core:strings"

POFile :: struct {
	pofile: string,
	wrapwidth: int,
	encoding: string,
	check_for_duplicates: bool,
}

POEntry :: struct {
	comment: string,
	tcomment: string,
	occurrences: [dynamic]string,
	flags: [dynamic]string,
	previous_msgctxt: string,
	previous_msgid: string,
	previous_msgid_plural: string,
	linenum: int,
}

parse_po_file :: proc(file_path: string) -> (result: []POEntry, err: string) {
	list_to_return: []POEntry
	fmt.println("parsing po")

	f, ferr := os.open(file_path)
	if ferr != nil {
		return nil, fmt.tprintf("%s", ferr)
	}
	defer os.close(f)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.to_stream(f), buffer[:])
	defer bufio.reader_destroy(&r)

	current_entry: POEntry
	current_line: int
	current_token: string

	defer delete(current_token)

	for {
		line, err := bufio.reader_read_string(&r, '\n', context.allocator)
		if err != nil {
			break
		}
		defer delete(line, context.allocator)

		line = strings.trim_right(line, "\r\n")
		current_line += 1
		if current_line == 1 {
			// TODO: Why do we need this check?
			fmt.printfln("%x", line)
			line = strings.trim_prefix(line, "\ufeff")
			fmt.printfln("%x", line)
		}
	}

	return list_to_return, ""
}

main :: proc() {
	fmt.println("hello world")
	parse_po_file("tests/feff1.po")
}
