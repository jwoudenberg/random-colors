from os import nil
from osproc import nil
from strutils import nil

proc with_default(str : string, default : string not nil): string not nil {.noSideEffect.} =
  if isNil(str) or str == "":
    return default
  else:
    return str

proc strip(str : string not nil): string not nil {.noSideEffect.} =
  let stripped = strutils.strip(str)
  if isNil(stripped):
    return ""
  else:
    return stripped

proc root(): string not nil =
  let (git_root, _) =
    osproc.execCmdEx(
      "git rev-parse --show-toplevel",
      options = { osproc.poUsePath }
    )
  return strip(with_default(git_root, "no-git-root"))

proc branch(): string not nil =
  let (git_branch, _) =
    osproc.execCmdEx(
      "git rev-parse --abbrev-ref HEAD",
      options = { osproc.poUsePath }
    )
  return strip(with_default(git_branch, "no-git-branch"))

proc key(): string not nil =
  let str = root() & ":" & branch()
  if isNil(str):
    assert(false)
  else:
    return str

## Encodes keys similar to fish's `escape --type var` for backwards compatibilty
## with the older fish version of this code.
proc encode(str : string not nil): string not nil {.noSideEffect.} =
  result = ""
  for c in str:
    if strutils.isAlphaNumeric(c):
      add(result, c)
    else:
      add(result, "_" & strutils.toHex(c) & "_")


echo encode(key())
