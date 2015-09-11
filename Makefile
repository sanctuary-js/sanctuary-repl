REPL_FILES = $(shell find test -name '*.repl' | sort)
EXP_FILES = $(REPL_FILES:.repl=.exp)


.PHONY: all
all: ramda.json sanctuary.json

ramda.raw.json: package.json
	curl --silent 'https://raine.github.io/ramda-json-docs/v$(shell node -p 'require("./$<").dependencies.ramda' | tr . _).json' >'$@'

ramda.json: ramda.raw.json
	node -p '\
	var o = {};\
	require("./$<").forEach(function(doc) { o[doc.name] = doc; doc.name = "R." + doc.name });\
	JSON.stringify(o, null, 2)' >'$@'

sanctuary.json: node_modules/sanctuary/index.js
	node -p '\
	var o = {};\
	var src = require("fs").readFileSync("./$<", {encoding: "utf8"});\
	for (var i = 0, lines = src.split("\n"); i < lines.length; i += 1) {\
	  var match = /^ *[/][/]# (.*) :: (.*)$$/.exec(lines[i]);\
	  if (match) {\
	    var name = match[1], sig = match[2], description = "";\
	    for (var j = i + 2; j < lines.length && (match = /^ *[/][/][.] ?(.*)$$/.exec(lines[j])); j += 1) {\
	      description += match[1] + "\n";\
	    }\
	    o[name.replace(/#/g, ".prototype.")] = {\
	      name: "S." + name,\
	      sig: sig,\
	      description: description.replace(/^```.*\n([\s\S]*)```\n/gm, function(_0, _1) {\
	        return _1.replace(/^(?!$$)/gm, "  ");\
	      }),\
	    };\
	  }\
	}\
	JSON.stringify(o, null, 2)' >'$@'


.PHONY: lint
lint:


.PHONY: setup
setup:
	npm install


.PHONY: test
test: $(EXP_FILES)
	printf '%s\n' $^ | xargs expect

test/%.exp: test/%.repl scripts/expify
	scripts/expify '$<' >'$@'
