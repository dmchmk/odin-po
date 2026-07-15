package po

import "core:fmt"
import "core:os"
import "core:bufio"
import "core:strings"

print_file :: proc(file_path: string) {
	f, ferr := os.open(file_path)
	if ferr != nil {
		return
	}
	defer os.close(f)

	r: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&r, os.to_stream(f), buffer[:])
	defer bufio.reader_destroy(&r)

	for {
		line, err := bufio.reader_read_string(&r, '\n', context.allocator)
		if err != nil {
			break
		}
		defer delete(line, context.allocator)

		line = strings.trim_right(line, "\r\n")
		fmt.println(line)
	}
}

main :: proc() {
	fmt.println("hello world")
	print_file("tests/django.po")
}
