// Generated by CoffeeScript 1.12.7
var FS, binary, chDir, chdir, cp, curry, dirname, eq, exist, exists, glob, isDirectory, isFile, isFunction, isKind, isPromise, isReadable, isString, isType, isWritable, join, ls, lsR, lsr, mkDir, mkDirP, mkdir, mkdirp, mv, promise, read, readBinaryStream, readBuffer, readDir, readStream, readdir, ref, ref1, ref2, rephrase, rm, rmDir, rmdir, stat, write,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

ref = require("path"), join = ref.join, dirname = ref.dirname;

import stream from "stream";

ref1 = require("panda-garden"), curry = ref1.curry, binary = ref1.binary;

ref2 = require("panda-parchment"), isType = ref2.isType, isKind = ref2.isKind, isFunction = ref2.isFunction, isString = ref2.isString, isPromise = ref2.isPromise, promise = ref2.promise, eq = ref2.eq, rephrase = ref2.rephrase;

import {
  Method
} from "fairmont-multimethods";

import fs from "fs";

import minimatch from "minimatch";

FS = rephrase("node", fs);

stat = FS.stat.stat;

exists = exist = function(path) {
  try {
    return (await(FS.stat(path))) != null;
  } catch (error1) {
    return false;
  }
};

isDirectory = function(path) {
  try {
    return (await(FS.stat(path))).isDirectory();
  } catch (error1) {
    return false;
  }
};

isFile = function(path) {
  try {
    return (await(FS.stat(path))).isFile();
  } catch (error1) {
    return false;
  }
};

isReadable = function(x) {
  var ref3;
  return (x != null ? (ref3 = x.read) != null ? ref3.call : void 0 : void 0) != null;
};

isWritable = function(x) {
  var ref3;
  return (x != null ? (ref3 = x.write) != null ? ref3.call : void 0 : void 0) != null;
};

read = Method.create();

Method.define(read, isString, isString, function(path, encoding) {
  return FS.readFile(path, encoding);
});

Method.define(read, isString, function(path) {
  return read(path, 'utf8');
});

readBuffer = function(path) {
  return FS.readFile(path);
};

Method.define(read, isString, eq(void 0), readBuffer);

Method.define(read, isString, eq("binary"), readBuffer);

Method.define(read, isString, eq("buffer"), readBuffer);

readStream = function(stream, encoding) {
  var buffer;
  if (encoding == null) {
    encoding = "utf8";
  }
  buffer = "";
  return promise(function(resolve, reject) {
    stream.on("data", function(data) {
      return buffer += data.toString(encoding);
    });
    stream.on("end", function() {
      return resolve(buffer);
    });
    return stream.on("error", function(error) {
      return reject(error);
    });
  });
};

readBinaryStream = function(stream) {
  var buffer;
  buffer = new Buffer(0);
  return promise(function(resolve, reject) {
    stream.on("data", function(data) {
      return buffer = Buffer.concat([buffer, data]);
    });
    stream.on("end", function() {
      return resolve(buffer);
    });
    return stream.on("error", function(error) {
      return reject(error);
    });
  });
};

Method.define(read, isReadable, readStream);

Method.define(read, isReadable, isString, readStream);

Method.define(read, isReadable, eq(void 0), readBinaryStream);

Method.define(read, isReadable, eq("binary"), readBinaryStream);

Method.define(read, isReadable, eq("buffer"), readBinaryStream);

write = Method.create();

Method.define(write, isString, isString, function(path, content) {
  return FS.writeFile(path, content);
});

Method.define(write, isString, isReadable, function(path, stream) {
  return stream.pipe(fs.createWriteStream(path));
});

Method.define(write, isWritable, isString, function(stream, content) {
  return promise(function(resolve, reject) {
    return stream.write(content, "utf-8", function(error) {
      if (error == null) {
        return resolve();
      } else {
        return reject(error);
      }
    });
  });
});

write = curry(binary(write));

readdir = readDir = function(path) {
  return FS.readdir(path);
};

ls = function(path) {
  var file, i, len, ref3, results;
  ref3 = await(readdir(path));
  results = [];
  for (i = 0, len = ref3.length; i < len; i++) {
    file = ref3[i];
    results.push(join(path, file));
  }
  return results;
};

lsR = lsr = function(path, visited) {
  var childPath, i, info, len, ref3;
  if (visited == null) {
    visited = [];
  }
  ref3 = await(ls(path));
  for (i = 0, len = ref3.length; i < len; i++) {
    childPath = ref3[i];
    if (!(indexOf.call(visited, childPath) >= 0)) {
      info = await(FS.lstat(childPath));
      if (info.isDirectory()) {
        await(lsR(childPath, visited));
      } else {
        visited.push(childPath);
      }
    }
  }
  return visited;
};

glob = function(pattern, path) {
  return minimatch.match(await(lsR(path)), join(path, pattern));
};

chDir = chdir = Method.create();

Method.define(chdir, isString, function(path) {
  var cwd;
  cwd = process.cwd();
  process.chdir(path);
  return function() {
    return process.chdir(cwd);
  };
});

Method.define(chdir, isString, isFunction, function(path, f) {
  var restore;
  restore = chdir(path);
  f();
  return restore();
});

rm = function(path) {
  return FS.unlink(path);
};

mv = curry(binary(function(old, _new) {
  return FS.rename(old, _new);
}));

cp = curry(binary(function(old, _new) {
  return promise(function(resolve, reject) {
    return (fs.createReadStream(old)).pipe(fs.createWriteStream(_new)).on("error", function(error) {
      return reject(error);
    }).on("close", function() {
      return resolve();
    });
  });
}));

rmDir = rmdir = function(path) {
  return FS.rmdir(path);
};

mkDir = mkdir = curry(binary(function(mode, path) {
  return FS.mkdir(path, mode);
}));

mkDirP = mkdirp = curry(binary(function(mode, path) {
  var error, parent;
  if (!(await(exists(path)))) {
    parent = dirname(path);
    if (!(await(exists(parent)))) {
      await(mkdirp(mode, parent));
    }
    try {
      return await(mkdir(mode, path));
    } catch (error1) {
      error = error1;
      if (error.code !== "EEXIST") {
        throw error;
      }
    }
  }
}));

module.exports = {
  read: read,
  write: write,
  stat: stat,
  exist: exist,
  exists: exists,
  isReadable: isReadable,
  isWritable: isWritable,
  isFile: isFile,
  isDirectory: isDirectory,
  readdir: readdir,
  readDir: readDir,
  ls: ls,
  lsR: lsR,
  lsr: lsr,
  glob: glob,
  mkdir: mkdir,
  mkDir: mkDir,
  mkdirp: mkdirp,
  mkDirP: mkDirP,
  chdir: chdir,
  chDir: chDir,
  cp: cp,
  mv: mv,
  rm: rm,
  rmdir: rmdir,
  rmDir: rmDir
};