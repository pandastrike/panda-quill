{join, dirname} = require "path"
{curry, binary} = require "fairmont-core"
{async} = require "fairmont-helpers"
{Method} = require "fairmont-multimethods"
{flatten} = require "fairmont-reactive"
{liftAll} = require "when/node"
{promise} = require "when"
FS = (liftAll require "fs")
fs = require "fs"
{Minimatch} = require "minimatch"

stat = (path) -> FS.stat path

exists = exist = async (path) ->
  try
    yield FS.stat path
    true
  catch
    false

read = Method.create()

Method.define read, String, String, (path, encoding) ->
  FS.readFile path, encoding

Method.define read, String, (path) -> read path, 'utf8'

readBuffer = (path) -> FS.readFile path
Method.define read, String, undefined, readBuffer
Method.define read, String, "binary", readBuffer
Method.define read, String, "buffer", readBuffer

stream = require "stream"
{promise} = require "when"

Method.define read, stream.Readable, (stream) ->
  buffer = ""
  promise (resolve, reject) ->
    stream.on "data", (data) -> buffer += data.toString()
    stream.on "end", -> resolve buffer
    stream.on "error", (error) -> reject error

readdir = readDir = (path) -> FS.readdir path

ls = async (path) ->
  (join path, file) for file in (yield readdir path)

lsR = lsr = async (path, visited = []) ->
  for childPath in (yield ls path)
    if !(childPath in visited)
      info = yield FS.lstat childPath
      if info.isDirectory()
        yield lsR childPath, visited
      else
        visited.push childPath
  visited

glob = async (pattern, path) ->
  minimatch = new Minimatch pattern
  match = (path) ->
    minimatch.match path
  _path for _path in (yield lsR path) when match _path

write = (path, content) -> FS.writeFile path, content

chDir = chdir = Method.create()

Method.define chdir, String, (path) ->
  cwd = process.cwd()
  process.chdir path
  -> process.chdir cwd

Method.define chdir, String, Function, (path, f) ->
  restore = chdir path
  f()
  restore()

rm = (path) -> FS.unlink path

rmDir = rmdir = (path) -> FS.rmdir path

isDirectory = async (path) -> (yield stat path).isDirectory()

isFile = async (path) -> (yield stat path).isFile()

mkDir = mkdir = curry binary (mode, path) -> FS.mkdir path, mode

mkDirP = mkdirp = curry binary async (mode, path) ->
  if !(yield exists path)
    parent = dirname path
    if !(yield exists parent)
      yield mkdirp mode, parent
    try
      yield mkdir mode, path
    catch error
      if error.code != "EEXIST"
        throw error

mv = curry binary (old, _new) -> FS.rename old, _new

cp = curry binary (old, _new) ->
  promise (resolve, reject) ->
    (fs.createReadStream old)
    .pipe(fs.createWriteStream _new)
    .on "error", (error) -> reject error
    .on "close", -> resolve()

module.exports = {read, write, rm, stat, exist, exists,
  isFile, isDirectory, readdir, readDir, ls, lsR, lsr, glob,
  mkdir, mkDir, mkdirp, mkDirP, chdir, chDir, rm, rmdir, rmDir,
  cp, mv}
