// Generated by CoffeeScript 2.6.1
(function() {
  //# libra/ry ####################################################################
  var all, clear, getType, global, isArray, isBool, isBoolean, isFunc, isFunction, isNull, isNumber, isObject, isString, isType, isUndefined, isVoid, libra, log, pack, packer, ry, scope, table, warn,
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  log = console.log;

  clear = console.clear;

  table = console.table;

  warn = console.warn;

  all = function*(arg) {
    while (true) {
      yield arg;
    }
  };

  packer = function(object) {
    return function(dict) {
      var key, results, val;
      results = [];
      for (key in dict) {
        if (!hasProp.call(dict, key)) continue;
        val = dict[key];
        results.push(object[key] = val);
      }
      return results;
    };
  };

  global = function(arg) {
    var key, val;
    if (arg == null) {
      arg = isObject(this) ? this : {};
    }
    for (key in arg) {
      if (!hasProp.call(arg, key)) continue;
      val = arg[key];
      //(warn '[global]: overwriting ' + key) if window[key]?
      window[key] = val;
    }
    return arg;
  };

  scope = function() {
    return arguments[0]();
  };

  libra = ry = {};

  pack = packer(libra);

  pack({all, packer, global, scope, log, clear, table, warn});

  //# types #######################################################################
  getType = (function() {
    var toString;
    toString = {}.toString;
    return function(arg) {
      return toString.call(arg).slice(8, -1);
    };
  })();

  isType = function(thing, types) {
    return types.hasOwnProperty(getType(thing));
  };

  isString = function(arg) {
    return isType(arg, {String});
  };

  isNumber = function(arg) {
    return (isType(arg, {Number})) && (!isNaN(arg));
  };

  isBoolean = function(arg) {
    return isType(arg, {Boolean});
  };

  isArray = function(arg) {
    return isType(arg, {Array});
  };

  isObject = function(arg) {
    return isType(arg, {Object});
  };

  isFunction = function(arg) {
    return isType(arg, {Function});
  };

  isUndefined = function(arg) {
    return isType(arg, {
      Undefined: void 0
    });
  };

  isNull = function(arg) {
    return isType(arg, {Null});
  };

  isBool = isBoolean;

  isVoid = isUndefined;

  isFunc = isFunction;

  pack({getType, isType, isString, isNumber, isBoolean, isArray, isObject, isFunction, isUndefined, isNull, isBool, isVoid, isFunc});

  //###############################################################################
  scope(function() {
    var getLines, isEven, isOdd, max, min, sleep, test, zFill;
    max = Math.max;
    min = Math.min;
    isEven = function(n) {
      return n % 2 === 0;
    };
    isOdd = function(n) {
      return n % 2 === !0;
    };
    getLines = function(arg) {
      return arg.split(/\r?\n/);
    };
    zFill = function(n, m) {
      return `${n}`.padStart(m, '0');
    };
    sleep = function(ms) {
      return new Promise(function(resolve) {
        return setTimeout(resolve, ms);
      });
    };
    test = {};
    return pack({max, min, isEven, isOdd, getLines, zFill, sleep, test});
  });

  //# repeat ######################################################################
  scope(function() {
    var buildObject, repeat;
    // repeat 5 -> ....
    repeat = function(n, f) {
      var i, results;
      i = 0;
      results = [];
      while (i++ < n) {
        results.push(f(i));
      }
      return results;
    };
    buildObject = function(keys, func) {
      var j, key, len, res;
      res = {};
      for (j = 0, len = keys.length; j < len; j++) {
        key = keys[j];
        res[key] = func(key);
      }
      return res;
    };
    return pack({repeat, buildObject});
  });

  //# functional ##################################################################
  scope(function() {
    var _, chain, curry, dot;
    _ = Symbol('_');
    curry = function(func, ...curryArgs) {
      return function(...args) {
        var arg, combinedArgs, idx, j, len;
        combinedArgs = Array.from(curryArgs);
        for (idx = j = 0, len = combinedArgs.length; j < len; idx = ++j) {
          arg = combinedArgs[idx];
          if (arg === _) {
            //log '>', arg, idx, combinedArgs[idx]
            combinedArgs[idx] = args.shift();
          }
        }
        return func(...(combinedArgs.concat(args)));
      };
    };
    chain = function(value) {
      return {
        value: value,
        then: function(func, ...args) {
          this.value = func(this.value, ...args);
          return this;
        },
        last: function(func, ...args) {
          return this.value = func(this.value, ...args);
        }
      };
    };
    dot = function(methodName, ...args) {
      return function(object) {
        return object[methodName](...args);
      };
    };
    //chain 'HELLO'
    //.then dot 'toLowerCase'
    //.then dot 'replace', 'h', 'ch'
    //.last log
    return pack({_, curry, chain, dot});
  });

  //# shuffle #####################################################################
  scope(function() {
    var random, randomColor, randomElement, randomFloat, randomInteger, shuffle;
    // shuffles array in place
    // uses fisher yates shuffle
    // https://bost.ocks.org/mike/shuffle/
    shuffle = function(array) {
      var i, m;
      m = array.length;
      // While there remain elements to shuffle…
      while (m) {
        // Pick a remaining element…
        i = Math.floor(random() * m--);
        // And swap it with the current element.
        [array[m], array[i]] = [array[i], array[m]];
      }
      //t = array[m]
      //array[m] = array[i]
      //array[i] = t
      return array;
    };
    pack({shuffle});
    //# Returns a random integer between min and max.
    //# Both upper and lower bound are inclusive.
    //# Based on code from mdn and personally tested.
    randomInteger = function(min, max) {
      var multiplier, randomNumber, result;
      min = Math.ceil(min);
      max = Math.floor(max);
      randomNumber = Math.random();
      multiplier = max - min + 1;
      result = randomNumber * multiplier + min;
      return Math.floor(result);
    };
    //# Returns a random float between min (inclusive)
    //# and max (exclusive). Based of code from mdn.
    randomFloat = function(min, max) {
      return Math.random() * (max - min) + min;
    };
    randomElement = function(array) {
      var lastIndex;
      lastIndex = array.length - 1;
      return array[randomInteger(0, lastIndex)];
    };
    randomColor = function() {
      return '#' + zFill(random(0, 16777215).toString(16), 6);
    };
    random = function(a, b) {
      if (a === void 0) {
        return Math.random();
      }
      if (Array.isArray(a)) {
        return randomElement(a);
      }
      if (b === void 0) {
        return randomInteger(1, a);
      }
      return randomInteger(a, b);
    };
    random.int = randomInteger;
    random.float = randomFloat;
    random.element = randomElement;
    random.color = randomColor;
    return pack({random});
  });

  //# html ########################################################################
  scope(function() {
    var buildObject, dot, html, select, selectAll;
    ({buildObject, dot} = libra);
    html = function(...nodes) {
      return html.replaceContent('body', ...nodes);
    };
    html.select = function(argA, argB) {
      if ((argA instanceof HTMLElement) && (arguments.length === 1)) {
        return argA;
      }
      if (isString(argA)) {
        (argA = document.querySelector(argA));
      }
      if (argB) {
        return argA.querySelector(argB);
      } else {
        return argA;
      }
    };
    html.selectAll = function(argA, argB) {
      if (argB && isString(argA)) {
        (argA = document.querySelector(argA));
      }
      if (argB) {
        return argA.querySelectorAll(argB);
      } else {
        return document.querySelectorAll(argA);
      }
    };
    ({select, selectAll} = html);
    html.title = function(title) {
      return select('title').text = title;
    };
    html.content = function(node) {
      if (isString(node)) {
        node = select(node);
      }
      return [...node.childNodes];
    };
    html.children = function(node) {
      if (isString(node)) {
        node = select(node);
      }
      return [...node.children];
    };
    html.appendContent = function(node, ...nodes) {
      if (isString(node)) {
        node = select(node);
      }
      node.append(...nodes);
      return node;
    };
    html.replaceContent = function(node, ...nodes) {
      html.removeContent(node);
      html.appendContent(node, ...nodes);
      return node;
    };
    //html.replace = (node, ...nodes) ->
    html.removeContent = function(node) {
      var child, j, len, ref;
      if (isString(node)) {
        node = select(node);
      }
      ref = html.content(node);
      for (j = 0, len = ref.length; j < len; j++) {
        child = ref[j];
        log(child.remove());
      }
      return node;
    };
    html.node = function(selector, ...args) {
      var arg, children, classes, func, funcs, id, j, k, key, len, len1, line, lines, node, options, ref, tag, val;
      //# selector ##
      tag = selector.match(/^[^ #.]*/);
      id = (ref = selector.match(/#[^ #.]*/)) != null ? ref[0].replace('#', '') : void 0;
      classes = Array.from(selector.matchAll(/[.][^ #.]*/g)).flat().join(' ').replaceAll('.', '');
      //# args ##
      options = {};
      children = [];
      funcs = [];
      if (id != null) {
        options.id = id;
      }
      for (j = 0, len = args.length; j < len; j++) {
        arg = args[j];
        if ((isString(arg)) || (arg instanceof Element)) {
          children.push(arg);
        }
        if (isFunction(arg)) {
          funcs.push(arg);
        }
        if (isObject(arg)) {
          Object.assign(options, arg);
        }
      }
      //# special properties ##
      classes = `${classes} ${options.class || ''}`.trim();
      if (classes !== '') {
        options.className = classes;
      }
      if (options.css) {
        options.style = options.css;
      }
      if (options.wsl) {
        lines = options.wsl.split(';').map(dot('trim')).filter(function(arg) {
          return arg !== '';
        });
        options.style = ((function() {
          var k, len1, results;
          results = [];
          for (k = 0, len1 = lines.length; k < len1; k++) {
            line = lines[k];
            results.push(css.parseLine(line));
          }
          return results;
        })()).join(' ');
      }
      //# create node ##
      node = document.createElement(tag);
      for (key in options) {
        val = options[key];
        (key in node ? node[key] = val : void 0);
      }
      node.append(...children);
      for (k = 0, len1 = funcs.length; k < len1; k++) {
        func = funcs[k];
        func(node, options);
      }
      return node;
    };
    html.parse = function(html) {
      return document.createRange().createContextualFragment(html);
    };
    html.elements = function(elements = html.elements.names) {
      if (isString(elements)) {
        elements = elements.split(' ');
      }
      return buildObject(elements, function(arg) {
        return ry.curry(html.node, arg);
      });
    };
    html.elements.names = "html head link meta style title body address article aside footer header h1 h2 h3 h4 h5 h6 main nav section blockquote dd div dl dt figcaption figure hr li ol p pre ul a abbr b bdi bdo br cite code data dfn em i kbd mark q rb rp rt rtc ruby s samp small span strong sub sup time u var wbr area audio img map track video embed iframe object param picture portal source svg math canvas noscript script del ins caption col colgroup table tbody td tfoot th thead tr button datalist fieldset form input label legend meter optgroup option output progress select textarea details dialog menu summary slot template".split(' ');
    return pack({html});
  });

  //# vault #######################################################################
  scope(function() {
    var vault, vaultClear, vaultRemove, vaultRetrieve, vaultStore;
    vaultStore = function(key, value) {
      return localStorage.setItem(key, JSON.stringify(value));
    };
    vaultRetrieve = function(key) {
      return JSON.parse(localStorage.getItem(key));
    };
    vaultRemove = function(key) {
      return localStorage.removeItem(key);
    };
    vaultClear = function() {
      return localStorage.clear();
    };
    vault = function(key, value) {
      if (arguments.length === 0) {
        return localStorage;
      }
      if (arguments.length === 1) {
        return vaultRetrieve(key);
      }
      if (arguments.length === 2) {
        return vaultStore(key, value);
      }
    };
    vault.store = vaultStore;
    vault.retrieve = vaultRetrieve;
    vault.set = vaultStore;
    vault.get = vaultRetrieve;
    vault.remove = vaultRemove;
    vault.delete = vaultRemove;
    vault.clear = vaultClear;
    vault.empty = vaultClear;
    return pack({vault});
  });

  //# tco #########################################################################
  scope(function() {
    var TCO, count, count2, goto, tco, test;
    TCO = Symbol('TCO');
    goto = function() {
      return [TCO, ...arguments];
    };
    tco = function(res) {
      while (true) {
        if ((Array.isArray(res)) && (res[0] === TCO)) {
          res.shift();
          res = res.shift()(...res);
        } else {
          return res;
        }
      }
    };
    pack({TCO, goto, tco});
    ({test} = libra);
    count = function(n) {
      if (n >= 1000000) {
        return n;
      }
      return goto(count, ++n);
    };
    count2 = function(n) {
      if (n >= 1000000) {
        return n;
      }
      return count2(++n);
    };
    test.countWithTCO = function() {
      return tco(count(0));
    };
    return test.countWithoutTCO = function() {
      return count2(0);
    };
  });

  //# css #########################################################################
  scope(function() {
    var buildChunks, countSpaces, css, handleSpecialChars, isOnlyWhitespace, preprocessLine, processBlock, processLine, processPart, select, translateLine;
    ({select} = libra.html);
    css = function(argA, argB) {
      //log argA, argB
      if ((isString(argA)) && (isUndefined(argB))) {
        return css.load(argA);
      }
      if ((isObject(argA)) && (isUndefined(argB))) {
        return css.bind(argA);
      }
      throw 'invalid css call';
    };
    css.preprocessors = {};
    css.stylesheets = {};
    css.bindings = {};
    css.lineSep = '\n';
    css.blockSep = '\n\n';
    css.remove = function(name) {
      css.stylesheets[name].remove();
      return delete css.stylesheets[name];
    };
    css.get = function(name) {
      return css.stylesheets[name];
    };
    css.getCSS = function(name) {
      return css.stylesheets[name].innerHTML;
    };
    css.disable = function(name) {
      return css.stylesheets[name].disabled = true;
    };
    css.enable = function(name) {
      return css.stylesheets[name].disabled = false;
    };
    css.load = function(qssCode) {
      var cssCode, name, node;
      [name, cssCode] = css.parse(qssCode);
      if (css.stylesheets[name]) {
        css.stylesheets[name].innerHTML = cssCode;
      } else {
        node = document.createElement('style');
        node.innerHTML = cssCode;
        css.stylesheets[name] = node;
        (select('head')).appendChild(node);
      }
      return name;
    };
    css.preload = function(qssCode) { // maybe
      var name;
      name = css.load(qssCode);
      css.disable(name);
      return name;
    };
    css.bind = function(bindings) {
      var cssCode, cssLines, key, node, ref, val;
      for (key in bindings) {
        val = bindings[key];
        css.bindings[key] = val;
      }
      cssLines = ['/* bindings.libra.css */', '', ':root {'];
      ref = css.bindings;
      for (key in ref) {
        val = ref[key];
        cssLines.push(`    --${key}: ${val};`);
      }
      cssLines.push('}');
      cssCode = cssLines.join('\n');
      if (css.stylesheets.bindings == null) {
        node = document.createElement('style');
        (select('head')).appendChild(node);
        css.stylesheets.bindings = node;
      }
      css.stylesheets.bindings.innerHTML = cssCode;
    };
    css.parse = function(qssCode) {
      var animations, block, blocks, cssBlocks, cssCode, cssLines, getLines, j, len, name, states, stylesheetName;
      ({getLines} = libra);
      cssLines = getLines(qssCode).map(function(line) {
        return line.trimEnd();
      }).filter(function(line) {
        return line !== '';
      });
      blocks = buildChunks(cssLines, 2);
      blocks = blocks.map(processBlock);
      stylesheetName = 'default';
      animations = {};
      cssBlocks = [];
      for (j = 0, len = blocks.length; j < len; j++) {
        block = blocks[j];
        switch (block[0][0]) {
          case 'name':
            stylesheetName = block[0][1];
            break;
          case 'select':
          case 'comment':
            cssBlocks.push(block[1]);
            break;
          case 'keyframe':
            name = block[0][1];
            if (animations[name] == null) {
              animations[name] = [];
            }
            animations[name].push(block[1]);
            break;
          default:
            log(block);
        }
      }
//log cssBlocks, animations
      for (name in animations) {
        states = animations[name];
        cssBlocks.push([`@keyframes ${name} {`, ...states, "}"].join(css.lineSep));
      }
      cssBlocks.unshift(`/* ${stylesheetName}.libra.css */`);
      cssCode = cssBlocks.join(css.blockSep);
      cssCode = handleSpecialChars(cssCode);
      return [stylesheetName, cssCode + '\n'];
    };
    buildChunks = function(lines, levels = 1) {
      var baseIndent, chunk, chunks, j, len, line, min;
      ({min} = libra);
      if (lines.length === 0) {
        return [];
      }
      baseIndent = min(...((function() {
        var j, len, results;
        results = [];
        for (j = 0, len = lines.length; j < len; j++) {
          line = lines[j];
          results.push(countSpaces(line));
        }
        return results;
      })()));
      if ((countSpaces(lines[0])) !== baseIndent) {
        throw 'IndentationError: first line not part of any chunk';
      }
      chunks = [];
      for (j = 0, len = lines.length; j < len; j++) {
        line = lines[j];
        if ((countSpaces(line)) === baseIndent) {
          chunks.push([]);
        }
        chunks[chunks.length - 1].push(line);
      }
      if (levels === 1) {
        return chunks;
      }
      return (function() {
        var k, len1, results;
        results = [];
        for (k = 0, len1 = chunks.length; k < len1; k++) {
          chunk = chunks[k];
          results.push([[chunk[0]]].concat(buildChunks(chunk.slice(1), levels - 1)));
        }
        return results;
      })();
    };
    countSpaces = function(line) {
      var i;
      i = 0;
      while (line[i] === ' ') {
        i++;
      }
      return i;
    };
    processBlock = function(block) {
      var animation, head, index, line, percentage, ref, tail;
      if (block[0][0].startsWith('#')) {
        return [['#']];
      }
      line = block[0][0];
      index = line.indexOf(' ');
      if (index === -1) {
        head = line;
        tail = '';
      } else {
        head = line.slice(0, index);
        tail = line.slice(index).trim();
      }
      //log head
      if (head === 'name') {
        return [[head, tail], ' '];
      }
      if (head === 'comment') {
        block[0] = '/* ' + tail.trim();
        block.push('*/');
        return [[head], block.join(css.lineSep).replaceAll(/\n[ ]*/g, '\n')];
      }
      block = block.map(processLine).filter(isOnlyWhitespace);
      if (head === 'select') {
        block[0] = `${tail} {`;
        block.push("}");
        return [[head], block.join(css.lineSep)];
      }
      if (head === 'keyframe') {
        ref = tail.split(' '), [animation] = ref, [percentage] = slice.call(ref, -1);
        block[0] = `${percentage} {`;
        block.push("}");
        return [[head, animation], block.join(css.lineSep)];
      }
      throw `LSS Error: block cannot start with '${head}'`;
    };
    isOnlyWhitespace = function(arg) {
      return arg.trim().length !== 0;
    };
    processLine = function(line) {
      var ref;
      line = line.map(processPart).join(' ');
      if ((ref = line.split(' ', 1)[0]) === 'SELECT' || ref === 'KEYFRAME' || ref === 'NAME') {
        return line;
      }
      if (line.startsWith('#')) {
        return ' ';
      }
      //line = line.replaceAll('#', '').trim()
      //return "/ * #{line} * /"
      return (preprocessLine(line)).split('\n').map(translateLine).join(css.lineSep);
    };
    preprocessLine = function(line) {
      var index, preprocFunc;
      // helper for css.parse

      // get first word of line
      index = line.indexOf(' ');
      if (index === -1) {
        index = line.length;
      }
      // if first line has preprocessor registered, use it.
      // otherwise, return line unchanged.
      preprocFunc = css.preprocessors[line.substring(0, index)];
      if (isFunction(preprocFunc)) {
        return preprocFunc(line);
      } else {
        return line;
      }
    };
    translateLine = function(line) {
      var head, index, tail;
      index = line.indexOf(' ');
      if (index === -1) {
        return line + ':;';
      }
      head = line.slice(0, index);
      tail = line.slice(index);
      return `${head}:${tail};`;
    };
    processPart = function(part) {
      return part.trim();
    };
    handleSpecialChars = function(str) {
      return str.replaceAll(' (', ' calc(').replaceAll(/\$([a-zA-Z0-9-_]+):/g, '--$1:').replaceAll(/\$([a-zA-Z0-9-_]+)/g, 'var(--$1)');
    };
    css.parseLine = function(line) {
      return handleSpecialChars(processLine([line]));
    };
    return pack({css});
  });

  //# css preprocs ################################################################
  scope(function() {
    var css;
    ({css} = libra);
    css.preprocessors.bg = function(arg) {
      return arg.replace('bg', 'background');
    };
    return css.preprocessors.fullscreen = function() {
      return `height 100vh
width 100vw
margin 0`;
    };
  });

  //# bytes <> hex ###############################################################
  scope(function() {
    var bytesToHex, hexToBytes;
    bytesToHex = function(bytes) {
      if (isType(bytes, {ArrayBuffer})) {
        bytes = new Uint8Array(bytes);
      }
      if (isType(bytes, {Uint8Array})) {
        bytes = Array.from(bytes);
      }
      return bytes.map(function(byte) {
        return byte.toString(16).padStart(2, '0');
      }).join('');
    };
    hexToBytes = function(hex) {
      var _, i, j, len, results;
      results = [];
      for (i = j = 0, len = hex.length; j < len; i = j += 2) {
        _ = hex[i];
        results.push(parseInt(hex.slice(i, +(i + 1) + 1 || 9e9), 16));
      }
      return results;
    };
    return pack({hexToBytes, bytesToHex});
  });

  //# secret ######################################################################
  scope(function() {
    var algoParams, decrypt, digest, encrypt, exportKey, generateKey, importKey, keyGenParams, keyImportParams;
    algoParams = {
      aesCtr: function({counter} = {}) {
        if (counter) {
          counter = new Uint8Array(hexToBytes(counter));
        } else {
          counter = crypto.getRandomValues(new Uint8Array(16));
        }
        return {
          name: "AES-CTR",
          counter,
          length: 64
        };
      }
    };
    keyGenParams = {
      aesCtr: {
        name: "AES-CTR",
        length: 256
      }
    };
    keyImportParams = {
      aesCtr: {
        name: "AES-CTR"
      }
    };
    encrypt = async function(key, message, {algorithm, mode} = {}) {
      var counter, encryptedMessage, params;
      if (algorithm == null) {
        algorithm = 'aesCtr';
      }
      key = (await importKey(key, ['encrypt']));
      params = algoParams[algorithm]();
      if (mode === 'hex') {
        message = hexToBytes(message);
      }
      if (isString(message)) {
        message = (new TextEncoder()).encode(message);
      }
      if (isArray(message)) {
        message = new Uint8Array(message);
      }
      encryptedMessage = (await crypto.subtle.encrypt(params, key, message));
      counter = bytesToHex(params.counter);
      encryptedMessage = bytesToHex(encryptedMessage);
      return {counter, encryptedMessage};
    };
    decrypt = async function(key, data, {algorithm, mode} = {}) {
      var encryptedMessage, message, params;
      if (algorithm == null) {
        algorithm = 'aesCtr';
      }
      key = (await importKey(key, ['decrypt']));
      params = algoParams[algorithm](data);
      encryptedMessage = new Uint8Array(hexToBytes(data.encryptedMessage));
      message = (await crypto.subtle.decrypt(params, key, encryptedMessage));
      if (mode === 'hex') {
        return bytesToHex(message);
      }
      return (new TextDecoder()).decode(message);
    };
    generateKey = async function(algorithm = 'aesCtr') {
      var key, params;
      params = keyGenParams[algorithm];
      key = (await crypto.subtle.generateKey(params, true, ['encrypt']));
      return exportKey(key);
    };
    exportKey = async function(key) {
      var rawKey;
      rawKey = (await crypto.subtle.exportKey('raw', key));
      return bytesToHex(rawKey);
    };
    importKey = async function(key, usages, algorithm = 'aesCtr') {
      var params;
      key = new Uint8Array(hexToBytes(key));
      params = keyImportParams[algorithm];
      key = (await crypto.subtle.importKey('raw', key, params, true, usages));
      return key;
    };
    digest = async function(message, algorithm = 'sha256') {
      var digested;
      message = (new TextEncoder()).encode(message);
      algorithm = algorithm.replace('sha', 'SHA-');
      digested = (await crypto.subtle.digest(algorithm, message));
      return bytesToHex(digested);
    };
    window.testSecret = async function() {
      var decMsg, encMsg, key, msg;
      msg = 'test';
      key = (await generateKey());
      log(key);
      encMsg = (await encrypt(key, msg));
      log(encMsg);
      decMsg = (await decrypt(key, encMsg));
      log(decMsg);
      return msg === decMsg;
    };
    return pack({
      secret: {encrypt, decrypt, generateKey, digest}
    });
  });

  //# lock ########################################################################

  // TODO:
  // add pageKeyGen
  // import select, vault, css, secret, etc
  scope(function() {
    var br, css, curry, div, html, input, lock, lockPage, pageKeyHashes, secret, select, span, vault;
    ({html, vault, secret, css} = libra);
    ({div, span, input, br} = html.elements());
    ({select} = html);
    curry = "2dd86aa78506478b72062af767d91221d9f7c4946604cc1f325ac224bf2825a8";
    lock = async function(pageName, callback) {
      var key, ref;
      //log vault.get('pageKeys')?[pageName]

      //[type, page, key] = vault.get('pageKeys')?[pageName]?.split('/') ? []
      key = (ref = vault.get('pageKeys')) != null ? ref[pageName] : void 0;
      if (((await secret.digest(key + curry))) === pageKeyHashes[pageName]) {
        log('automatic login succeeded');
        callback(key);
        return;
      }
      return lockPage(pageName, callback);
    };
    lockPage = function(pageName, callback) {
      var changeHandler, lockHTML;
      lockHTML = div({
        id: 'lockDiv'
      }, span({
        id: 'lockSpan'
      }, 'enter password'), br(), input({
        id: 'lockInput',
        type: 'password'
      }));
      changeHandler = async function() {
        var key, pageKeys, ref;
        //input = select('input').value
        //key = input.split('/')[2]
        key = select('input').value;
        if (((await secret.digest(key + curry))) === pageKeyHashes[pageName]) {
          pageKeys = (ref = vault.get('pageKeys')) != null ? ref : {};
          pageKeys[pageName] = key;
          vault.set('pageKeys', pageKeys);
          css.remove('lockScreen');
          return callback(key);
        } else {
          select('input').value = '';
          return select('#lockSpan').innerText = 'try again';
        }
      };
      html(lockHTML);
      select('input').addEventListener('change', changeHandler);
      return css(`
name lockScreen

select body
    fullscreen
    display grid
    grid-template-rows 1fr max-content 1fr
    bg black

select #lockDiv
    display block
    grid-row 2
    place-self center
    text-align center
    font-family sans-serif
    font-size 18px
    font-wight bold
    color grey

select #lockInput
    margin-top 10px
    border none
    bg black
    font-size 18px
    color grey

select #lockInput:focus
    caret-color transparent
    border-left 1px solid grey
    border-right 1px solid grey
    padding 0px 5px

select *:focus
    outline none
`);
    };
    pageKeyHashes = {
      bot: "95e60ac0a4e2a25363a0a9bc740495a28ff0f0b91218f9bc13356a9182a51e1e",
      demo: "63b88c44aebb2f1c5d3b1799e95a46afe2ebf4617fae8557567d21f7891d268d",
      rome: "54b9a608f51165c1ee8bf5477bbf7100e6a6697e02b681c21e9233a3bc8aca7d",
      blink: "525c839422ea399f8137aacdb74e62a747a03589143ac031713c5fb5aec1f87f"
    };
    return pack({lock});
  });

  //# fetchJSON ###################################################################
  scope(function() {
    var fetchJSON;
    fetchJSON = async function(url) {
      var json, response;
      response = (await fetch(url));
      json = (await response.json());
      return json;
    };
    return pack({fetchJSON});
  });

  //###############################################################################
  scope(function() {
    var re, t, tokenize;
    re = /("|')((?:\\\1|(?:(?!\1).))*)\1|[\w\d-]*\(|\)|[$]?[\w\d-]+:?|[-+\/*%=,;|]+/g;
    tokenize = function(line) {
      var res, token;
      res = [];
      while (true) {
        token = re.exec(line);
        if (token == null) {
          break;
        }
        res.push(token[0]);
      }
      return res;
    };
    pack({tokenize});
    return t = `fullscreen
font bold 400px sans-serif
display grid
place-content center
textClip url('../../demo/canyon.jpg')
user-select none`;
  });

  // console.log(tokenize(t))

  // ry.repeat 20, -> log tokenize 'fullscreen'
  window.libra = libra;

}).call(this);