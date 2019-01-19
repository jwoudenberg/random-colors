from os import nil
from ospaths import nil
from osproc import nil
from strutils import `%`
from httpclient import nil
from parseopt import nil
import json

const schemeDir = ".colorschemes"

type
  Location = distinct (string)
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

proc withDefault(str : string, default : string): string {.noSideEffect.} =
  if isNil(str) or str == "":
    return default
  else:
    return str

proc strip(str : string): string {.noSideEffect.} =
  strutils.strip(str)

proc root(): string =
  let (gitRoot, _) =
    osproc.execCmdEx(
      "git rev-parse --show-toplevel",
      options = { osproc.poUsePath }
    )
  return strip(withDefault(gitRoot, "no-git-root"))

proc branch(): string =
  let (gitBranch, _) =
    osproc.execCmdEx(
      "git rev-parse --abbrev-ref HEAD",
      options = { osproc.poUsePath }
    )
  return strip(withDefault(gitBranch, "no-git-branch"))

proc key(): string =
  "$1:$2" % [root(), branch()]

## Encodes keys similar to fish's `escape --type var` for backwards
## compatibility with the older fish version of this code.
proc encode(str : string): Location {.noSideEffect.} =
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
  return ColorValue(getBiggestInt(value))

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

proc setColor(key: string, color: Color): string {.noSideEffect.} =
  let hex = "$1$2$3" % [
    strutils.toHex(color.red, 2),
    strutils.toHex(color.green, 2),
    strutils.toHex(color.blue, 2)
  ]
  # This is an iterm2 specific escape code for setting terminal colors.
  # See: https://iterm2.com/documentation-escape-codes.html
  "\x1b]1337;SetColors=$1=$2\x07" % [key, hex]

proc setScheme(scheme: Scheme): void =
  write(stdout, setColor("fg", scheme.foreground))
  write(stdout, setColor("bg", scheme.background))
  write(stdout, setColor("black", scheme.background))
  write(stdout, setColor("red", scheme.dark))
  write(stdout, setColor("green", scheme.main))
  write(stdout, setColor("yellow", scheme.light))
  write(stdout, setColor("blue", scheme.main))
  write(stdout, setColor("magenta", scheme.dark))
  write(stdout, setColor("cyan", scheme.light))
  write(stdout, setColor("white", scheme.foreground))
  write(stdout, setColor("br_black", scheme.background))
  write(stdout, setColor("br_red", scheme.dark))
  write(stdout, setColor("br_green", scheme.main))
  write(stdout, setColor("br_yellow", scheme.light))
  write(stdout, setColor("br_blue", scheme.main))
  write(stdout, setColor("br_magenta", scheme.dark))
  write(stdout, setColor("br_cyan", scheme.light))
  write(stdout, setColor("br_white", scheme.foreground))
  flushFile(stdout)

proc refresh(): void =
  let location = getLocation()
  let scheme = newScheme(location)
  setScheme(scheme)

proc load(): void =
  let location = getLocation()
  var scheme: Scheme
  try:
    scheme = readScheme(location)
  except IOError:
    scheme = newScheme(location)
  setScheme(scheme)

proc help(): void =
  echo("Usage: random-colors [OPTION]")
  echo("Load a random terminal color scheme for the current git project branch.")
  echo("If a scheme has already been generated for this branch, reload it.")
  echo("")
  echo("  --help       Show this help message")
  echo("  --refresh    Create a new color scheme for this branch, potentially overwriting an existing one.")

proc main(): void =
  for kind, key, val in parseopt.getopt():
    case key:
      of "refresh":
        refresh()
      of "help":
        help()
      else:
        write(stderr, "Unknown command line argument: $1\n\n" % key)
        help()
        quit(QuitFailure)
  load()

main()
