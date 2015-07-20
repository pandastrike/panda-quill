{createReadStream} = require "fs"
{join} = require "path"
assert = require "assert"
Amen = require "amen"

Amen.describe "File system functions", (context) ->

  {read, write, rm, stat, exist, exists,
    isFile, isDirectory, readdir, readDir,
    ls, lsR, lsr, glob, mkdir, mkDir, mkdirp, mkDirP,
    chdir, chDir, rmdir, rmDir} = require "../src"

  context.test "stat", ->
    assert (yield stat "test/data/lines.txt").size?

  context.test "exists", ->
    assert (yield exists "test/data/lines.txt")
    assert !(yield exists "test/data/does-not-exist")

  do ->

    context.test "read", ->
      assert (yield read "test/data/lines.txt") == "one\ntwo\nthree\n"

      context.test "write", ->
        write "test/data/lines.txt", (yield read "test/data/lines.txt")

    context.test "read buffer", ->
      assert (yield read "test/data/lines.txt", "binary").constructor == Buffer

    context.test "read stream", ->
      s = createReadStream "test/data/lines.txt"
      assert (yield read s) == "one\ntwo\nthree\n"

  context.test "readdir", ->
    assert "lines.txt" in (yield readdir "test/data")

  context.test "ls", ->

    context.test "lsR", ->
      testDir = join __dirname, ".."
      assert (join testDir, "test/data/lines.txt") in (yield lsR testDir)

  context.test "glob", ->
    src = join __dirname, "..", "src"
    assert ((join src, "index.litcoffee") in
      (yield glob "**/*.litcoffee", src))

  context.test "chdir", ->
    src = join __dirname, "..", "src"
    cwd = process.cwd()
    chdir src, ->
      fs = require "fs"
      assert (fs.statSync "index.litcoffee").size?
    assert cwd == process.cwd()

  context.test "rm"

  context.test "rmdir", ->

    context.test "mkdir", ->
      yield mkdir '0777', "./test/data/foobar"
      assert (yield isDirectory "./test/data/foobar")
      yield rmdir "./test/data/foobar"

    context.test "mkdirp", ->
      yield mkdirp '0777', "./test/data/foo/bar"
      assert (yield isDirectory "./test/data/foo/bar")
      yield rmdir "./test/data/foo/bar"
      yield rmdir "./test/data/foo"

  context.test "isDirectory", ->
    assert (yield isDirectory "./test/data")

  context.test "isFile", ->
    assert (yield isFile "./test/data/lines.txt")
