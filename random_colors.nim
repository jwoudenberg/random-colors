from os import nil
from ospaths import nil
from osproc import nil
from strutils import `%`
from not_nil import prove
from httpclient import nil
import json

const schemeDir = ".colorschemes"

type
  Location = distinct (string not nil)
  ColorValue = range[0..256]
  Color = tuple[red: ColorValue, green: ColorValue, blue: ColorValue]
  Scheme = tuple[foreground: Color, light: Color, main: Color, dark: Color, background: Color]

proc `%`(color: Color): JsonNode =
  return %* [color.red, color.green, color.blue ]

proc `%`(scheme: Scheme): JsonNode =
  return %* [
      % scheme.foreground,
      % scheme.light,
      % scheme.main,
      % scheme.dark,
      % scheme.background
    ]

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

proc get_location(): Location =
  return encode(key())

proc parse_color_value(value: JsonNode): ColorValue =
  return ColorValue(getNum(value))

proc parse_color(color: JsonNode): Color =
  return (
    red: parse_color_value(color[0]),
    green: parse_color_value(color[1]),
    blue: parse_color_value(color[2])
  )

proc scheme_from_json(json: JsonNode): Scheme {.noSideEffect.} =
  return (
    foreground: parse_color(json[0]),
    light: parse_color(json[1]),
    main: parse_color(json[2]),
    dark: parse_color(json[3]),
    background: parse_color(json[4])
  )

proc request_scheme(): Scheme =
  let client = httpclient.newHttpClient()
  var body = %* {"model": "ui"}
  let response = httpclient.postContent(client, "http://colormind.io/api/", pretty(body))
  let json = parseJson(response)
  return scheme_from_json(json["result"])

proc scheme_file_path(location: Location): string =
  let home = ospaths.getHomeDir()
  return ospaths.joinPath([home, schemeDir, string(location)])

proc save_scheme(location: Location, scheme : Scheme): void =
  let filename = scheme_file_path(location)
  let content = pretty(% scheme)
  writeFile(filename, content)

proc new_scheme(location: Location): Scheme =
  result = request_scheme()
  save_scheme(location, result)

proc read_scheme(location: Location): Scheme =
  let filename = scheme_file_path(location)
  let content = readFile(filename)
  let json = parseJson(content)
  return scheme_from_json(json)

proc load_scheme(location: Location): Scheme =
  try:
    result = read_scheme(location)
  except IOError:
    result = new_scheme(location)

proc main(): void =
  let location = get_location()
  echo string(location)
  let scheme = load_scheme(location)
  echo scheme

main()
