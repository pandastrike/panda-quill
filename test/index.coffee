{createReadStream} = require "fs"
{join} = require "path"
assert = require "assert"
Amen = require "amen"
fs = require "fs"

Amen.describe "File system functions", (context) ->

  {isReadable, isWritable,
    read, write, rm, stat, exist, exists,
    isFile, isDirectory, readdir, readDir,
    ls, lsR, lsr, glob, mkdir, mkDir, mkdirp, mkDirP,
    chdir, chDir, rm, rmdir, rmDir, cp, mv} = require "../src"

  testDirectory = join __dirname, "data"

  context.test "isReadable", ->
    assert isReadable process.stdin

  context.test "isWritable", ->
    assert isWritable process.stdout

  context.test "stat", ->
    info = yield stat join testDirectory, "lines.txt"
    assert info.mode? && info.uid? && info.gid? && info.size? &&
      info.atime? && info.mtime? && info.ctime?

  context.test "exists", ->
    assert.equal (yield exists join testDirectory, "lines.txt"), true
    assert.equal (yield exists join testDirectory, "does-not-exist"), false

  context.test "read", (context) ->

    path = join testDirectory, "pandas.txt"
    target = "pandas love bamboo\n"

    context.test "files", ->
      assert (yield read path) == target

    context.test "buffer", ->
      assert (yield read path, "buffer").toString() == target

    context.test "streams", ->
      stream = fs.createReadStream path
      assert (yield read stream) == target

  context.test "write", (context) ->
    path = join testDirectory, "time.txt"
    currentTime = Date.now().toString()

    context.test "string", ->
      yield write path, currentTime
      assert (yield read path) == currentTime

    context.test "stream"

    context.test "buffer"

  context.test "readDir", ->
    files = yield readDir testDirectory
    assert "lines.txt" in files
    assert "pandas.txt" in files

  context.test "ls", ->
    paths = yield ls testDirectory
    assert (join testDirectory, "lines.txt") in paths
    assert (join testDirectory, "pandas.txt") in paths

  context.test "lsR", ->
    paths = yield lsR testDirectory
    assert (join testDirectory, "lines.txt") in paths
    assert (join testDirectory, "pandas.txt") in paths
    assert (join testDirectory, "lsr", "pandas.txt") in paths

  context.test "glob", ->
    paths = yield glob "**/*.txt", testDirectory
    assert (join testDirectory, "lines.txt") in paths
    assert (join testDirectory, "pandas.txt") in paths
    assert (join testDirectory, "lsr", "pandas.txt") in paths

    paths = yield glob "data/*.txt", __dirname
    assert (join testDirectory, "lines.txt") in paths
    assert (join testDirectory, "pandas.txt") in paths
    assert !((join testDirectory, "lsr", "pandas.txt") in paths)

  context.test "chdir", (context) ->
    cwd = process.cwd()

    context.test "with restore", ->
      restore = chdir testDirectory
      assert process.cwd() == testDirectory
      assert restore.call?
      restore()
      assert process.cwd() == cwd

    context.test "with function", ->
      wd = undefined
      chdir testDirectory, -> wd = process.cwd()
      assert wd == testDirectory
      assert process.cwd() == cwd

  context.test "mv", ->
    from = join testDirectory, "mv", "pandas.txt"
    to = join testDirectory, "mv", "bamboo.txt"

    # move from -> to
    yield mv from, to
    assert !(yield exist from)
    assert yield exist to

    # now reverse it
    yield mv to, from
    assert !(yield exist to)
    assert yield exist from

  context.test "cp", ->
    from = join testDirectory, "cp", "pandas.txt"
    to = join testDirectory, "cp", "bamboo.txt"

    # cp from -> to
    yield cp from, to
    assert yield exist from
    assert yield exist to

    context.test "rm", ->
      # now reverse it
      yield rm to
      assert !(yield exist to)

  context.test "mkDir", ->
    path = join testDirectory, "mkdir"
    yield mkDir "0777", path

    assert yield exist path

    context.test "rmDir", ->
      yield rmDir path
      assert !(yield exist path)

  context.test "mkDirP", ->
    path = join testDirectory, "mkdirp", "nested"
    yield mkDirP "0777", path
    assert yield exist path

    # cleanup
    yield rmDir join testDirectory, "mkdirp", "nested"
    yield rmDir join testDirectory, "mkdirp"
    assert !(yield exist path)

  context.test "isDirectory", ->
    path = join testDirectory, "pandas.txt"
    assert yield isDirectory testDirectory
    assert !(yield isDirectory path)

  context.test "isFile", ->
    path = join testDirectory, "pandas.txt"
    assert yield isFile path
    assert !(yield isFile testDirectory)
