package tests

import "core:log"
import "core:testing"
import po ".."

@(test)
my_test :: proc(t: ^testing.T) {
	n := 2+2

	testing.expect(t, n == 4, "2 + 2 failed to equal 4")
}

@(test)
test_multiple_newlines :: proc(t: ^testing.T) {
	p := po.POFile{pofile="./tests/test_multiple_newlines.po"}
	po.parse_po_file(&p)
	testing.expectf(t, len(p.entries) == 2, "We got this many entries in POFile: %d", len(p.entries))
}
