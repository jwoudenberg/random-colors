from os import nil
from osproc import nil
from strutils import `%`
from not_nil import prove

type
  Location = distinct (string not nil)


proc with_default(str : string, default : string not nil): string not nil {.noSideEffect.} =
  if isNil(str) or str == "":
    return default
  else:
    return str

proc strip(str : string not nil): string not nil {.noSideEffect.} =
  let stripped = strutils.strip(str)
  prove(stripped)

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
  let str = "$1:$2" % [root(), branch()]
  return prove(str)

## Encodes keys similar to fish's `escape --type var` for backwards
## compatibility with the older fish version of this code.
proc encode(str : string not nil): Location {.noSideEffect.} =
  var encoded = ""
  for c in str:
    if strutils.isAlphaNumeric(c):
      add(encoded, c)
    else:
      add(encoded, "_$1_" % strutils.toHex(c))
  return (Location encoded)


echo string(encode(key()))
