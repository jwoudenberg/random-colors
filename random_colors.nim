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

proc withDefault(str : string, default : string not nil): string not nil {.noSideEffect.} =
  if isNil(str) or str == "":
    return default
  else:
    return str

proc strip(str : string not nil): string not nil {.noSideEffect.} =
  let stripped = strutils.strip(str)
  prove(stripped)

proc root(): string not nil =
  let (gitRoot, _) =
    osproc.execCmdEx(
      "git rev-parse --show-toplevel",
      options = { osproc.poUsePath }
    )
  return strip(withDefault(gitRoot, "no-git-root"))

proc branch(): string not nil =
  let (gitBranch, _) =
    osproc.execCmdEx(
      "git rev-parse --abbrev-ref HEAD",
      options = { osproc.poUsePath }
    )
  return strip(withDefault(gitBranch, "no-git-branch"))

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

proc getLocation(): Location =
  return encode(key())

proc parseColorValue(value: JsonNode): ColorValue =
  return ColorValue(getNum(value))

proc parseColor(color: JsonNode): Color =
  return (
    red: parseColorValue(color[0]),
    green: parseColorValue(color[1]),
    blue: parseColorValue(color[2])
  )

proc schemeFromJson(json: JsonNode): Scheme {.noSideEffect.} =
  return (
    foreground: parseColor(json[0]),
    light: parseColor(json[1]),
    main: parseColor(json[2]),
    dark: parseColor(json[3]),
    background: parseColor(json[4])
  )

proc requestScheme(): Scheme =
  let client = httpclient.newHttpClient()
  var body = %* {"model": "ui"}
  let response = httpclient.postContent(client, "http://colormind.io/api/", pretty(body))
  let json = parseJson(response)
  return schemeFromJson(json["result"])

proc schemeFilePath(location: Location): string =
  let home = ospaths.getHomeDir()
  return ospaths.joinPath([home, schemeDir, string(location)])

proc saveScheme(location: Location, scheme : Scheme): void =
  let filename = schemeFilePath(location)
  let content = pretty(% scheme)
  writeFile(filename, content)

proc newScheme(location: Location): Scheme =
  result = requestScheme()
  saveScheme(location, result)

proc readScheme(location: Location): Scheme =
  let filename = schemeFilePath(location)
  let content = readFile(filename)
  let json = parseJson(content)
  return schemeFromJson(json)

proc loadScheme(location: Location): Scheme =
  try:
    result = readScheme(location)
  except IOError:
    result = newScheme(location)

proc main(): void =
  let location = getLocation()
  echo string(location)
  let scheme = loadScheme(location)
  echo scheme

main()
