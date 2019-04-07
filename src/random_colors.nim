from os import nil
from ospaths import nil
from osproc import nil
from re import `re`
from strutils import `%`
from httpclient import nil
from parseopt import nil
import json
import strformat

const schemeDir = "random-colors/schemas"
const fishHookCode = staticRead("./hooks/hook.fish")

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

proc strip(str : string): string {.noSideEffect.} =
  strutils.strip(str)

proc key(): string =
  let (key, code) =
    osproc.execCmdEx(
      "git rev-parse --show-toplevel --abbrev-ref HEAD",
      options = { osproc.poUsePath }
    )
  if code == 0:
    return strip(key)
  else:
    return "no-git"

proc getLocation(): Location =
  return Location strutils.toHex(key())

proc parseColorValue(value: JsonNode): ColorValue =
  return ColorValue(getInt(value))

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
  let config = ospaths.getConfigDir()
  return ospaths.joinPath([config, schemeDir, string(location)])

proc saveScheme(location: Location, scheme : Scheme): void =
  let home = ospaths.getHomeDir()
  let filename = schemeFilePath(location)
  let content = pretty(% scheme)
  os.createDir(ospaths.parentDir(filename))
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

proc makeAbsolute(path : string): string =
  if os.isAbsolute(path):
    return path
  else:
    let cwd = os.getCurrentDir()
    return ospaths.joinPath([cwd, path])

proc pathToSelfBin(): string =
  let path = os.paramStr(0)
  return makeAbsolute(path)

proc hook(shell : string): void =
  case shell:
    of "fish":
      let bin = pathToSelfBin()
      let hookCode = re.replace(fishHookCode, re"random_colors_bin_path", bin)
      echo(hookCode)
    else:
      write(stderr, fmt("Unsupported shell {shell}. Only `fish` is currently supported\n\n"))
      quit(QuitFailure)

proc help(): void =
  echo("Usage: random-colors [OPTION]")
  echo("Load a random terminal color scheme for the current git project branch.")
  echo("If a scheme has already been generated for this branch, reload it.")
  echo("")
  echo("  --help       Show this help message")
  echo("  --refresh    Create a new color scheme for this branch.")
  echo("               If a color scheme already exists, it will be overwritten.")
  echo("  --hook       Enable random-colors for your fish shell session.")
  echo("               Usage: `random-colors --hook=fish | source`")

proc main(): void =
  for kind, key, val in parseopt.getopt():
    case key:
      of "refresh":
        refresh()
        return
      of "help":
        help()
        return
      of "hook":
        hook(val)
        return
      else:
        write(stderr, "Unknown command line argument: $1\n\n" % key)
        help()
        quit(QuitFailure)
  load()

main()
