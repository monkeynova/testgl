OUT=build
GENERATED=.generated

NPM=$(shell which npm)
NPM_OPTS=$(shell echo $(NPM) | grep -P 'cygdrive|~|home' > /dev/null && echo -g)

EXT_JS=webgl-utils.js jquery-1.9.1.min.js glMatrix-0.9.5.min.js jquery.base64.js

SIZES=1000 10000 100000 200000
MODELS=armadillo

SIZED_MODELS=$(foreach model,$(MODELS),$(model) $(foreach size,$(SIZES),$(model).$(size)))

SOURCE_FILES=index.jade code.coffee

all: $(EXT_JS:%=$(OUT)/%) $(SIZED_MODELS:%=$(OUT)/%.model.js) $(OUT)/README.html

serve:
	http-server $(OUT)

test:
	prove -r tests

clean:
	rm -rf $(OUT) $(GENERATED)

neat:
	rm -f *~
	rm -f \#*\#
	rm -f .\#*

include $(GENERATED)/build_dependencies.d
include $(SOURCE_FILES:%=$(GENERATED)/%.d)

$(OUT)/README.html: README.md
	@mkdir -p $(@D)
	marked --gfm $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/build_dependencies.d: node_dependencies.txt Makefile
	@mkdir -p $(@D)
	sort node_dependencies.txt | diff -C 2 --label SORTED - node_dependencies.txt
	npm bin > /dev/null
	@for dep in `cat node_dependencies.txt`; \
	do \
		shell_npm_opts=$(NPM_OPTS); \
		dep=`echo $$dep | perl -ne 's/-local$$// and $$exit = 1; print; exit $$exit'`; \
		if [ $$? = 1 ]; then shell_npm_opts=; fi; \
		npm list $$shell_npm_opts $$dep | grep empty > /dev/null || continue; \
		echo npm install $$shell_npm_opts $$dep; \
		npm install $$shell_npm_opts $$dep; \
	done
	echo > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.d: % ./tools/mkdep.coffee
	@mkdir -p $(@D)
	coffee ./tools/mkdep.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.model.js: ./tools/mk%.coffee ./tools/vec.coffee
	@mkdir -p $(@D)
	coffee $< > $@.tmp
	mv $@.tmp $@

$(OUT)/%.model.js: $(GENERATED)/%.model.js
	@mkdir -p $(@D)
	cp $< $@.tmp
	mv $@.tmp $@

define SIZED_RULE
$(OUT)/%.$(1).model.js: $(OUT)/%.model.js ./tools/simplify-model.coffee
	coffee ./tools/simplify-model.coffee $$< $$@.tmp $(1)
	mv $$@.tmp $$@
endef

$(foreach size,$(SIZES),$(eval $(call SIZED_RULE,$(size))))

$(GENERATED)/%.model.js: ./%.ply ./tools/ply2json.coffee ./tools/ply.coffee
	@mkdir -p $(@D)
	coffee ./tools/ply2json.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/terrain.model.js: terrain.png ./tools/image_to_terrain.coffee ./tools/vec.coffee
	coffee ./tools/image_to_terrain.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.dataurl.coffee: %.png ./tools/dataurl.coffee
	@mkdir -p $(@D)
	coffee ./tools/dataurl.coffee $(patsubst %.png,%,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/wave_bumpmap.png: ./tools/mkwave_bumpmap.coffee ./tools/vec.coffee
	@mkdir -p $(@D)
	coffee $< $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.dataurl.coffee: $(GENERATED)/%.png ./tools/dataurl.coffee
	@mkdir -p $(@D)
	coffee ./tools/dataurl.coffee $(patsubst %.png,%,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.model.dataurl.coffee: %.model.js ./tools/dataurl.coffee
	@mkdir -p $(@D)
	jslint $<
	coffee ./tools/dataurl.coffee $(patsubst %.model.js,%_model,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.model.dataurl.coffee: $(GENERATED)/%.model.js ./tools/dataurl.coffee
	@mkdir -p $(@D)
	jslint $<
	coffee ./tools/dataurl.coffee $(patsubst %.model.js,%_model,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.skel.dataurl.coffee: %.skel.js ./tools/dataurl.coffee
	@mkdir -p $(@D)
	jslint $<
	coffee ./tools/dataurl.coffee $(patsubst %.skel.js,%_skel,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(OUT)/%.js: $(GENERATED)/%.coffee
	@mkdir -p $(@D)
	coffee -p $< > $@.tmp
	mv $@.tmp $@

$(OUT)/%: %
	@mkdir -p $(@D)
	cp $< $@.tmp
	mv $@.tmp $@

$(OUT)/webgl-utils.js:
	@mkdir -p $(@D)
	curl -s http://learningwebgl.com/lessons/lesson03/webgl-utils.js > $@.tmp
	mv $@.tmp $@

$(OUT)/jquery-1.9.1.min.js:
	@mkdir -p $(@D)
	curl -s http://code.jquery.com/jquery-1.9.1.min.js > $@.tmp
	mv $@.tmp $@

$(OUT)/glMatrix-0.9.5.min.js:
	@mkdir -p $(@D)
	curl -s https://glmatrix.googlecode.com/files/glMatrix-0.9.5.min.js > $@.tmp
	mv $@.tmp $@

$(OUT)/jquery.base64.js:
	@mkdir -p $(@D)
	curl -s https://raw.github.com/carlo/jquery-base64/master/jquery.base64.js > $@.tmp
	mv $@.tmp $@
