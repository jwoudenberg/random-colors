from os import nil
from osproc import nil
from re import `re`
from strutils import `%`
from httpclient import nil
from parseopt import nil
import json
import strformat

type Location = distinct (string)
type ColorValue = range[0..256]
type Color = tuple[red: ColorValue, green: ColorValue, blue: ColorValue]
type Scheme = tuple[foreground: Color, light: Color, main: Color, dark: Color,
      background: Color]
type Term = enum iterm, xterm

const schemeDir = "random-colors/schemas"
const fishHookCode = staticRead("./hooks/hook.fish")
const bashHookCode = staticRead("./hooks/hook.bash")

proc `%`(color: Color): JsonNode =
  return %* [color.red, color.green, color.blue]

proc `%`(scheme: Scheme): JsonNode =
  return %* [
      % scheme.foreground,
      % scheme.light,
      % scheme.main,
      % scheme.dark,
      % scheme.background
    ]

proc strip(str: string): string {.noSideEffect.} =
  strutils.strip(str)

proc toLocation(filename: string): Location =
  let config = os.getConfigDir()
  os.createDir(os.joinPath([config, schemeDir]))
  return Location os.joinPath([config, schemeDir, filename])

proc defaultLocation(): Location =
  return toLocation("default")

proc getLocation(): Location =
  let (key, code) =
    osproc.execCmdEx(
      "git rev-parse --show-toplevel --abbrev-ref HEAD",
      options = {osproc.poUsePath}
    )
  if code == 0:
    return toLocation(strutils.toHex(strip(key)))
  else:
    return defaultLocation()

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
  let response = httpclient.postContent(client, "http://colormind.io/api/",
      pretty(body))
  let json = parseJson(response)
  return schemeFromJson(json["result"])

proc schemeFilePath(location: Location): string {.noSideEffect.} =
  return string(location)

proc saveScheme(location: Location, scheme: Scheme): void =
  let filename = schemeFilePath(location)
  let content = pretty( % scheme)
  os.createDir(os.parentDir(filename))
  writeFile(filename, content)

proc createSymlink(src: Location, destination: Location): void =
  if not os.fileExists(schemeFilePath(destination)):
    os.createSymlink(schemeFilePath(src), schemeFilePath(destination))

proc newScheme(location: Location): Scheme =
  # Getting a colorscheme might take some time, might even fail if the colormind
  # website is down. To this end we will temporarily link to the default scheme
  # while the request is underway. The presence of this link will prevent
  # parallel invocations of `random-colors` from fetching their own schema.
  # Should a request fail the user won't see a new error for every prompt.
  createSymlink(defaultLocation(), location)
  result = requestScheme()
  os.removeFile(schemeFilePath(location))
  saveScheme(location, result)

proc readScheme(location: Location): Scheme =
  let filename = schemeFilePath(location)
  let content = readFile(filename)
  let json = parseJson(content)
  return schemeFromJson(json)

proc setColorIterm(key: string, color: Color): string {.
    noSideEffect.} =
  let hex = "$1$2$3" % [
    strutils.toHex(color.red, 2),
    strutils.toHex(color.green, 2),
    strutils.toHex(color.blue, 2)
  ]
  # This is an iterm2 specific escape code for setting terminal colors.
  # See: https://iterm2.com/documentation-escape-codes.html
  "\x1b]1337;SetColors=$1=$2\x07" % [key, hex]

proc setColorXterm(key: string, color: Color): string {.
    noSideEffect.} =
  let hex = "$1$2$3" % [
    strutils.toHex(color.red, 2),
    strutils.toHex(color.green, 2),
    strutils.toHex(color.blue, 2)
  ]
  # This is an XTerm escape code for setting terminal colors. Many other
  # terminals also support them.
  # See: http://pod.tst.eu/http://cvs.schmorp.de/rxvt-unicode/doc/rxvt.7.pod#XTerm_Operating_System_Commands
  "\x1b]$1;#$2\x07" % [key, hex]

proc setSchemeIterm(scheme: Scheme): void =
  write(stdout, setColorIterm("fg", scheme.foreground))
  write(stdout, setColorIterm("bg", scheme.background))
  write(stdout, setColorIterm("black", scheme.background))
  write(stdout, setColorIterm("red", scheme.dark))
  write(stdout, setColorIterm("green", scheme.main))
  write(stdout, setColorIterm("yellow", scheme.light))
  write(stdout, setColorIterm("blue", scheme.main))
  write(stdout, setColorIterm("magenta", scheme.dark))
  write(stdout, setColorIterm("cyan", scheme.light))
  write(stdout, setColorIterm("white", scheme.foreground))
  write(stdout, setColorIterm("br_black", scheme.background))
  write(stdout, setColorIterm("br_red", scheme.dark))
  write(stdout, setColorIterm("br_green", scheme.main))
  write(stdout, setColorIterm("br_yellow", scheme.light))
  write(stdout, setColorIterm("br_blue", scheme.main))
  write(stdout, setColorIterm("br_magenta", scheme.dark))
  write(stdout, setColorIterm("br_cyan", scheme.light))
  write(stdout, setColorIterm("br_white", scheme.foreground))
  flushFile(stdout)

proc setSchemeXterm(scheme: Scheme): void =
  write(stdout, setColorXterm("10", scheme.foreground))
  write(stdout, setColorXterm("11", scheme.background))
  write(stdout, setColorXterm("4;0", scheme.background))
  write(stdout, setColorXterm("4;1", scheme.dark))
  write(stdout, setColorXterm("4;2", scheme.main))
  write(stdout, setColorXterm("4;3", scheme.light))
  write(stdout, setColorXterm("4;4", scheme.main))
  write(stdout, setColorXterm("4;5", scheme.dark))
  write(stdout, setColorXterm("4;6", scheme.light))
  write(stdout, setColorXterm("4;7", scheme.foreground))
  write(stdout, setColorXterm("4;8", scheme.background))
  write(stdout, setColorXterm("4;9", scheme.dark))
  write(stdout, setColorXterm("4;10", scheme.main))
  write(stdout, setColorXterm("4;11", scheme.light))
  write(stdout, setColorXterm("4;12", scheme.main))
  write(stdout, setColorXterm("4;13", scheme.dark))
  write(stdout, setColorXterm("4;14", scheme.light))
  write(stdout, setColorXterm("4;15", scheme.foreground))
  flushFile(stdout)

proc setScheme(term: Term, scheme: Scheme): void =
  case term:
    of xterm:
      setSchemeXterm(scheme)
    of iterm:
      setSchemeIterm(scheme)

proc refresh(term: Term): void =
  let location = getLocation()
  let scheme = newScheme(location)
  setScheme(term, scheme)

proc load(term: Term): void =
  let location = getLocation()
  var scheme: Scheme
  try:
    scheme = readScheme(location)
  except IOError:
    scheme = newScheme(location)
  setScheme(term, scheme)

proc getTerm(): Term =
  let termAppEnv = os.getEnv("TERM_PROGRAM")
  case termAppEnv:
    of "iTerm.app": iterm
    else: xterm

proc hook(shell: string): void =
  let bin = os.getAppFilename()
  let hookCodeTemplate =
    case shell:
      of "fish": fishHookCode
      of "bash": bashHookCode
      else:
        write(stderr, fmt(
            "Unsupported shell {shell}. Only `fish` is currently supported\n\n"))
        quit(QuitFailure)
  let hookCode = re.replace(hookCodeTemplate, re"random_colors_bin_path", bin)
  echo(hookCode)

proc help(): void =
  echo("Usage: random-colors [OPTION]")
  echo("Load a random terminal color scheme for the current git branch.")
  echo("If a scheme has already been generated for this branch, reload it.")
  echo("")
  echo("  --help       Show this help message")
  echo("  --refresh    Create a new color scheme for this branch.")
  echo("               If one already exists, it will be overwritten.")
  echo("  --hook       Enable random-colors for your shell session.")
  echo("               For bash: `eval \"$(random-colors --hook=bash)\"")
  echo("               For fish: `random-colors --hook=fish | source`")

proc main(): void =
  let term = getTerm()
  for kind, key, val in parseopt.getopt():
    case key:
      of "refresh":
        refresh(term)
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
  load(term)

main()
