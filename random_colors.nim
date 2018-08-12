from os import nil
from osproc import nil
from strutils import `%`
from not_nil import prove
from httpclient import nil
import json

type
  Location = distinct (string not nil)
  ColorValue = range[0..256]
  Color = tuple[red: ColorValue, green: ColorValue, blue: ColorValue]
  Scheme = tuple[foreground: Color, light: Color, main: Color, dark: Color, background: Color]


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

proc parse_color_value(value: JsonNode): ColorValue =
  return ColorValue(getNum(value))

proc parse_color(color: JsonNode): Color =
  return (
    red: parse_color_value(color[0]),
    green: parse_color_value(color[1]),
    blue: parse_color_value(color[2])
  )

proc request_colors(loc : Location): Scheme =
  let client = httpclient.newHttpClient()
  var body = %* {"model": "ui"}
  let response = httpclient.postContent(client, "http://colormind.io/api/", pretty(body))
  let json = parseJson(response)
  return (
    foreground: parse_color(json["result"][0]),
    light: parse_color(json["result"][1]),
    main: parse_color(json["result"][2]),
    dark: parse_color(json["result"][3]),
    background: parse_color(json["result"][4])
  )

echo request_colors(encode(key()))
