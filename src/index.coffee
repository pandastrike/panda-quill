{join, dirname} = require "path"
stream = require "stream"
{promise} = require "when"
{curry, binary} = require "fairmont-core"
{async, promise, lift,
  isType, isKind, isFunction, isString, isPromise,
  eq} = require "fairmont-helpers"
{Method} = require "fairmont-multimethods"
FS = (lift require "fs")
fs = require "fs"
minimatch = require "minimatch"

{stat} = FS

exists = exist = async (path) ->
  try
    (yield FS.stat path)?
  catch
    false

isDirectory = async (path) ->
  try
    (yield stat path).isDirectory()
  catch
    false

isFile = async (path) ->
  try
    (yield stat path).isFile()
  catch
    false

isReadable = (x) -> x?.read?.call?

# socket-based streams are duplex streams
# and do not inherit from stream.writable
isWritable = (x) -> x?.write?.call?

read = Method.create()

Method.define read, isString, isString,
  (path, encoding) ->
    FS.readFile path, encoding

Method.define read, isString, (path) -> read path, 'utf8'

readBuffer = (path) -> FS.readFile path
Method.define read, isString, (eq undefined), readBuffer
Method.define read, isString, (eq "binary"), readBuffer
Method.define read, isString, (eq "buffer"), readBuffer

# Stringifies a stream's buffer according to the given encoding.
readStream = (stream, encoding = "utf8") ->
  buffer = ""
  promise (resolve, reject) ->
    stream.on "data", (data) -> buffer += data.toString(encoding)
    stream.on "end", -> resolve buffer
    stream.on "error", (error) -> reject error

# Extracts a stream's raw buffer.
readBinaryStream = (stream) ->
  buffer = new Buffer(0)
  promise (resolve, reject) ->
    stream.on "data", (data) -> buffer = Buffer.concat [buffer, data]
    stream.on "end", -> resolve buffer
    stream.on "error", (error) -> reject error

Method.define read, isReadable, readStream
Method.define read, isReadable, isString, readStream
Method.define read, isReadable, (eq undefined), readBinaryStream
Method.define read, isReadable, (eq "binary"), readBinaryStream
Method.define read, isReadable, (eq "buffer"), readBinaryStream

write = Method.create()

Method.define write, isString, isString,
  (path, content) -> FS.writeFile path, content

Method.define write, isString, isReadable,
  (path, stream) -> stream.pipe fs.createWriteStream path

Method.define write, isWritable, isString,
  (stream, content) ->
    promise (resolve, reject) ->
      stream.write content, "utf-8", (error) ->
        if !error?
          resolve()
        else
          reject error

# TODO: Add buffer support?

write = curry binary write

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
  minimatch.match (yield lsR path), (join path, pattern)

chDir = chdir = Method.create()

Method.define chdir, isString, (path) ->
  cwd = process.cwd()
  process.chdir path
  -> process.chdir cwd

Method.define chdir, isString, isFunction, (path, f) ->
  restore = chdir path
  f()
  restore()

rm = (path) -> FS.unlink path

mv = curry binary (old, _new) -> FS.rename old, _new

cp = curry binary (old, _new) ->
  promise (resolve, reject) ->
    (fs.createReadStream old)
    .pipe(fs.createWriteStream _new)
    .on "error", (error) -> reject error
    .on "close", -> resolve()

rmDir = rmdir = (path) -> FS.rmdir path

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

module.exports = {read, write, stat, exist, exists,
  isReadable, isWritable, isFile, isDirectory,
  readdir, readDir, ls, lsR, lsr, glob,
  mkdir, mkDir, mkdirp, mkDirP, chdir, chDir,
  cp, mv, rm, rmdir, rmDir}
