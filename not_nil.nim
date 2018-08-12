proc expect(v: string, msg: string not nil): string not nil =
  if isNil(v):
    assert(false)
  else:
    return v

proc prove*(v: string): string not nil =
  v.expect("Unwrap a nil string")
