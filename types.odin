package po

POFile :: struct {
	pofile: string,
	wrapwidth: int,
	encoding: string,
	check_for_duplicates: bool,
}

POEntry :: struct {
	msgid: string,
	msgstr: string,
	msgid_plural: string,
	msgstr_plural: map[string]string,
	msgctxt: string,
	obsolete: bool,
	encoding: string,

	// comment: string,
	// tcomment: string,
	// occurrences: [dynamic]string,
	// flags: [dynamic]string,
	// previous_msgctxt: string,
	// previous_msgid: string,
	// previous_msgid_plural: string,
	// linenum: int,
}
