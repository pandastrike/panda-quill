import {createReadStream} from "fs"
import {resolve, join} from "path"
import assert from "assert"
import {print as _print, test, success} from "amen"
import fs from "fs"
import {isFunction} from "panda-parchment"

import {isReadable, isWritable,
  read, write, rm, stat, exist, exists,
  isFile, isDirectory, readdir, readDir,
  ls, lsR, lsr, glob, mkdir, mkDir, mkdirp, mkDirP,
  chdir, chDir, rmdir, rmDir, rmR, rmr,
  cp, mv, run, print, abort} from "../src/index.js"

testDirectory = resolve "test", "data"

do ->

  _print await test "Panda Quill",  [

    test "isReadable", ->
      assert isReadable process.stdin

    test "isWritable", ->
      assert isWritable process.stdout

    test "stat", ->
      info = await stat join testDirectory, "lines.txt"
      assert info.mode? && info.uid? && info.gid? && info.size? &&
        info.atime? && info.mtime? && info.ctime?

    test "exists", ->
      assert.equal (await exists join testDirectory, "lines.txt"), true
      assert.equal (await exists join testDirectory, "does-not-exist"), false

    test "read", do ->

      path = join testDirectory, "pandas.txt"
      target = "Pandas love bamboo.\n"

      [
        test "files", ->
          assert (await read path) == target

        test "buffer", ->
          assert (await read path, "buffer").toString() == target

        test "streams", ->
          stream = fs.createReadStream path
          assert (await read stream) == target
      ]


    test "write", do ->

      path = join testDirectory, "time.txt"
      currentTime = Date.now().toString()

      [

        test "string", ->
          await write path, currentTime
          assert (await read path) == currentTime

        test "stream"

        test "buffer"

      ]

    test "readDir", ->
      files = await readDir testDirectory
      assert "lines.txt" in files
      assert "pandas.txt" in files

    test "ls", ->
      paths = await ls testDirectory
      assert (join testDirectory, "lines.txt") in paths
      assert (join testDirectory, "pandas.txt") in paths

    test "lsR", ->
      paths = await lsR testDirectory
      assert (join testDirectory, "lines.txt") in paths
      assert (join testDirectory, "pandas.txt") in paths
      assert (join testDirectory, "lsr", "pandas.txt") in paths

    test "rmR", ->
      # minimal test here, just make sure fn is exported
      assert isFunction rmr
      assert isFunction rmR

    test "glob", ->
       paths = await glob "**/*.txt", testDirectory
       assert (join testDirectory, "lines.txt") in paths
       assert (join testDirectory, "pandas.txt") in paths
       assert (join testDirectory, "lsr", "pandas.txt") in paths

       paths = await glob "data/*.txt", resolve "test"
       assert (join testDirectory, "lines.txt") in paths
       assert (join testDirectory, "pandas.txt") in paths
       assert !((join testDirectory, "lsr", "pandas.txt") in paths)

    test "chdir", do ->

      cwd = process.cwd()

      [

        test "with restore", ->
          restore = chdir testDirectory
          assert process.cwd() == testDirectory
          assert restore.call?
          restore()
          assert process.cwd() == cwd

        test "with function", ->
          wd = undefined
          chdir testDirectory, -> wd = process.cwd()
          assert wd == testDirectory
          assert process.cwd() == cwd

      ]

    test "mv", ->

      from = join testDirectory, "mv", "pandas.txt"
      to = join testDirectory, "mv", "bamboo.txt"

      # move from -> to
      await mv from, to
      assert !(await exist from)
      assert await exist to

      # now reverse it
      await mv to, from
      assert !(await exist to)
      assert await exist from

    test "cp/rm", ->

      from = join testDirectory, "pandas.txt"
      to = join testDirectory, "bamboo.txt"

      # cp from -> to
      await cp from, to
      assert await exist from
      assert await exist to

      # now reverse it
      await rm to
      assert !(await exist to)

    test "mkDir/rmDir", ->

      path = join testDirectory, "mkdir"
      await mkDir "0777", path

      assert await exist path

      await rmDir path
      assert !(await exist path)


    test "mkDirP", ->
      path = join testDirectory, "mkdirp", "nested"
      await mkDirP "0777", path
      assert await exist path

      # cleanup
      await rmDir join testDirectory, "mkdirp", "nested"
      await rmDir join testDirectory, "mkdirp"
      assert !(await exist path)

    test "isDirectory", ->
      path = join testDirectory, "pandas.txt"
      assert await isDirectory testDirectory
      assert !(await isDirectory path)

    test "isFile", ->
      path = join testDirectory, "pandas.txt"
      assert await isFile path
      assert !(await isFile testDirectory)

  test "abort", ->
    assert isFunction abort

  test "print", ->
    assert isFunction print

  test "run", ->
    assert.equal "hello",
      (await run "bash -c 'echo -n hello'").stdout

  ]

  process.exit if success then 0 else 1
