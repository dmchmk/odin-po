package po

POFile :: struct {
	pofile: string,
	wrapwidth: int,
	encoding: string,
	check_for_duplicates: bool,
	entries: [dynamic]POEntry,
	metadata: map[string]string,
}

POEntry :: struct {
	msgid: string `fmt:"s"`,
	msgstr: string `fmt:"s"`,
	msgid_plural: string,
	msgstr_plural: map[string]string,
	msgctxt: string,
	obsolete: bool,
	encoding: string,

	// comment: string,
	// tcomment: string,
	references: [dynamic]string `fmt:"s"`,
	// flags: [dynamic]string,
	// previous_msgctxt: string,
	// previous_msgid: string,
	// previous_msgid_plural: string,
	// linenum: int,
}
