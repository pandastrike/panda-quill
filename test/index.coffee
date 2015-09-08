{createReadStream} = require "fs"
{join} = require "path"
assert = require "assert"
Amen = require "amen"
fs = require "fs"

Amen.describe "File system functions", (context) ->

  {read, write, rm, stat, exist, exists,
    isFile, isDirectory, readdir, readDir,
    ls, lsR, lsr, glob, mkdir, mkDir, mkdirp, mkDirP,
    chdir, chDir, rm, rmdir, rmDir, cp, mv} = require "../src"

  testDir = join __dirname, "test-data"

  context.test "stat", ->
    resultKeys = Object.keys(yield stat join testDir, "lines.txt")
    statKeys = [ 'dev', 'mode', 'nlink', 'uid', 'gid', 'rdev', 'blksize',
      'ino', 'size', 'blocks', 'atime', 'mtime', 'ctime', 'birthtime' ]

    assert.deepEqual resultKeys, statKeys

  context.test "exists", ->
    assert (yield exists join testDir, "lines.txt") == true
    assert (yield exists join testDir, "does-not-exist") == false

  context.describe "read", ->
    # Files
    #------------------------
    result = yield read join testDir, "lines.txt"
    assert result == "one\ntwo\nthree\n"

    result = yield read "#{__dirname}/test-data/panda.txt", "buffer"
    assert.deepEqual result, new Buffer("Pandas love bamboo.")

    #TODO - Come up with a simple way to test different string encodings.

    # Streams
    #------------------------
    stream = fs.createReadStream "#{__dirname}/test-data/panda.txt"
    a = yield read stream
    assert a == "Pandas love bamboo."

    c = yield read stream, "buffer"
    assert.deepEqual c, new Buffer("Pandas love bamboo.")

    #TODO - Come up with a simple way to test different string encodings.

  context.test "write", ->
    # Store something unique in a file.
    currentTime = Date.now().toString()
    yield write "#{testDir}/time.txt", currentTime

    # Read back the data and see if it worked.
    value = yield read "#{testDir}/time.txt"
    assert value == currentTime

  context.test "readDir", ->
    dir = join testDir, "nested-test"
    files = yield readDir dir
    expectedValues = [ "app", "index.coffee", "index.css", "index.html" ]
    assert.deepEqual files, expectedValues

  context.test "ls", ->
    dir = join testDir, "nested-test"
    files = yield ls dir
    expectedValues = [
      "#{dir}/app"
      "#{dir}/index.coffee"
      "#{dir}/index.css"
      "#{dir}/index.html"
    ]
    assert.deepEqual files, expectedValues

  context.test "lsR", ->
    dir = join testDir, "nested-test"
    files = yield lsR dir
    expectedValues = [
      "#{dir}/app/index.coffee"
      "#{dir}/app/index.html"
      "#{dir}/index.coffee"
      "#{dir}/index.css"
      "#{dir}/index.html"
    ]
    assert.deepEqual files, expectedValues

  context.test "glob", ->
    dir = join testDir, "nested-test"

    files = yield glob "#{dir}/*.coffee", dir
    expectedValues = [
      "#{dir}/index.coffee"
    ]
    assert.deepEqual files, expectedValues

    # With the Globstar, you get any file within the tree that matches.
    files = yield glob "**/*.coffee", dir
    expectedValues = [
      "#{dir}/app/index.coffee"
      "#{dir}/index.coffee"
    ]
    assert.deepEqual files, expectedValues

    # Match for everything in the top-level directory, equivalent to "ls".
    files = yield glob "#{dir}/*", dir
    expectedValues = [
      "#{dir}/index.coffee"
      "#{dir}/index.css"
      "#{dir}/index.html"
    ]
    assert.deepEqual files, expectedValues

    # Match everything, equivalent to "lsR".
    files = yield glob "**/*", dir
    expectedValues = [
      "#{dir}/app/index.coffee"
      "#{dir}/app/index.html"
      "#{dir}/index.coffee"
      "#{dir}/index.css"
      "#{dir}/index.html"
    ]
    assert.deepEqual files, expectedValues

    files = yield glob "**/signup*", dir
    expectedValues = []
    assert.deepEqual files, expectedValues


  context.test "chdir", ->
    dir = join testDir, "nested-test"
    cwd = process.cwd()

    # We can change the working directory.
    goBack = chdir "#{dir}/app"
    assert process.cwd() == "#{dir}/app"

    # Now, restore the working directory.
    goBack()
    assert process.cwd() == cwd

    # Using chdir with a function results in no change after executing.
    f = -> "foobar"
    chdir "#{dir}/app", f
    assert process.cwd() == cwd


  context.test "mv", ->
    dir = join testDir, "file-test"
    oldData = "2Pandas love bamboo."
    yield write "#{dir}/first", oldData

    yield mv "#{dir}/first", "#{dir}/second"

    # Check that the first file is gone and its data is in the second.
    assert (yield exist "#{dir}/first") == false
    newData = yield read "#{dir}/second"
    assert newData == oldData
    yield rm "#{dir}/second"

  context.test "cp", ->
    dir = join testDir, "file-test"
    oldData = "Pandas love bamboo."
    yield write "#{dir}/third", oldData

    yield cp "#{dir}/third", "#{dir}/fourth"

    # Check that the first file is still there and its data is in the second.
    assert (yield exist "#{dir}/third") == true
    newData = yield read "#{dir}/fourth"
    assert newData == oldData
    yield rm "#{dir}/third"
    yield rm "#{dir}/fourth"

  context.test "rm", ->
    dir = join testDir, "file-test"
    oldData = "Pandas love bamboo."
    yield write "#{dir}/fifth", oldData

    yield rm "#{dir}/fifth"

    # Check that the first file is gone.
    assert (yield exist "#{dir}/fifth") == false

  context.test "rmdir", ->
    dir = join testDir, "dir-test"
    yield mkDir "0777", "#{dir}/first"

    yield rmDir "#{dir}/first"

    # Check that the directory is gone.
    assert (yield exist "#{dir}/first") == false

  context.test "mkdir", ->
    dir = join testDir, "dir-test"

    # Check that we don't already have a directory.
    assert (yield exist "#{dir}/second") == false

    # Create. Check that we have a directory now.
    yield mkDir "0777", "#{dir}/second"
    assert (yield exist "#{dir}/second") == true

    yield rmDir "#{dir}/second"

  context.test "mkdirp", ->
    dir = join testDir, "dir-test"

    # Check that we don't already have a directory.
    assert (yield exist "#{dir}/third") == false
    assert (yield exist "#{dir}/third/test") == false

    # Create. Check that we have a directory now.
    yield mkDirP "0777", "#{dir}/third/test"
    assert (yield exist "#{dir}/third/test") == true

    yield rmDir "#{dir}/third/test"
    yield rmDir "#{dir}/third"

  context.test "isDirectory", ->
    dir = join testDir, "nested-test"
    assert (yield isDirectory "#{dir}/app") == true
    assert (yield isDirectory "#{dir}/index.coffee") == false

  context.test "isFile", ->
    dir = join testDir, "nested-test"
    assert (yield isFile "#{dir}/app") == false
    assert (yield isFile "#{dir}/index.coffee") == true
