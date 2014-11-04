# Makefile Usage
# make lint -- linting
# make uglify -- compile minified source file
# make tarball -- create dfb.tar.gz file suitable for deployment as a website

# Name of minified output file
dfbjs := js/dfb.min.js
minified := js/utils.min.js js/worker.min.js

# locations of javascript source files
src_before := src/view/view.js
src_after := src/main.js
src_skip := src/utils.js src/worker.js
src := $(wildcard src/*.js src/view/*.js)

src := $(filter-out $(min_js) $(src_skip) $(src_before) $(src_after),$(src))
src := $(src_before) $(src) $(src_after)

css := $(wildcard css/*.css)
lib := $(wildcard lib/*)

dfb_files := index.html $(dfbjs) $(minified) \
    $(css) $(lib) fonts/

lint:
	jslint --regexp --todo --white $(src) $(src_skip)

uglify: $(dfbjs) $(minified)

copyright := '// An Interactive Topic Model of Signs. Except where noted, all source code, text, and graphics are copyright 2014 Andrew Goldstone, Susana Galán, C. Laura Lovin, Andrew Mazzaschi, and Lindsey Whitmore.'

$(minified): js/%.min.js: src/%.js
	uglifyjs $< --mangle --preamble $(copyright) -o $@

$(dfbjs): $(src)
	uglifyjs $(src) --mangle --preamble $(copyright) -o $@

dfb.tar.gz: $(dfb_files)
	rm -f $@
	tar -cvzf $@ $(dfb_files) data/*

tarball: dfb.tar.gz

site: uglify

.DEFAULT_GOAL := site

.PHONY: lint uglify tarball site
