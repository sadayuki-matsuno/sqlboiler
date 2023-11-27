// buildUpsertQueryPostgres builds a SQL statement string using the upsertData provided.
func buildUpsertQueryPostgres(dia drivers.Dialect, tableName string, updateOnConflict bool, ret, update, conflict, whitelist []string) string {
	conflict = strmangle.IdentQuoteSlice(dia.LQ, dia.RQ, conflict)
	whitelist = strmangle.IdentQuoteSlice(dia.LQ, dia.RQ, whitelist)
	ret = strmangle.IdentQuoteSlice(dia.LQ, dia.RQ, ret)

	buf := strmangle.GetBuffer()
	defer strmangle.PutBuffer(buf)

	columns := "DEFAULT VALUES"
	if len(whitelist) != 0 {
		columns = fmt.Sprintf("(%s) VALUES (%s)",
			strings.Join(whitelist, ", "),
			strmangle.Placeholders(dia.UseIndexPlaceholders, len(whitelist), 1, 1))
	}

	fmt.Fprintf(
		buf,
		"INSERT INTO %s %s ON CONFLICT ",
		tableName,
		columns,
	)

	if 0 < len(conflict) {
		buf.WriteByte('(')
		buf.WriteString(strings.Join(conflict, ", "))
		buf.WriteByte(')')
	}

	if !updateOnConflict || len(update) == 0 {
		buf.WriteString(" DO NOTHING")
	} else {
		buf.WriteString(" DO UPDATE SET ")

		for i, v := range update {
		    if len(v) == 0 {
		        continue
		    }
			if i != 0 {
				buf.WriteByte(',')
			}
			quoted := strmangle.IdentQuote(dia.LQ, dia.RQ, v)
			buf.WriteString(quoted)
			buf.WriteString(" = EXCLUDED.")
			buf.WriteString(quoted)
		}
	}

	if len(ret) != 0 {
		buf.WriteString(" RETURNING ")
		buf.WriteString(strings.Join(ret, ", "))
	}

	return buf.String()
}
