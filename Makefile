OUT=build
GENERATED=.generated

NPM=$(shell which npm)
NPM_OPTS=$(shell echo $(NPM) | grep ~ > /dev/null && echo -g)

EXT_JS=webgl-utils.js jquery-1.9.1.min.js glMatrix-0.9.5.min.js jquery.base64.js

all: $(patsubst %,$(OUT)/%,$(EXT_JS)) $(OUT)/README.html

clean:
	rm -rf $(OUT) $(GENERATED)

neat:
	rm -f *~
	rm -f \#*\#
	rm -f .\#*

include $(GENERATED)/build_dependencies.d
include $(GENERATED)/index.jade.d
include $(GENERATED)/code.coffee.d

$(OUT)/README.html: README.md
	@mkdir -p $(@D)
	marked --gfm $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/build_dependencies.d: node_dependencies.txt
	@mkdir -p $(@D)
	sort node_dependencies.txt | diff -C 2 --label SORTED - node_dependencies.txt
	npm bin > /dev/null
	@for dep in `cat node_dependencies.txt`; \
	do \
		npm list $(NPM_OPTS) $$dep | grep empty > /dev/null || continue; \
		echo npm install $(NPM_OPTS) $$dep; \
		npm install $(NPM_OPTS) $$dep; \
	done
	echo > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.d: % ./tools/mkdep.coffee
	@mkdir -p $(@D)
	coffee ./tools/mkdep.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.model.js: ./tools/mk%.coffee
	@mkdir -p $(@D)
	coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/terrain.model.js: terrain.png ./tools/image_to_terrain.coffee
	coffee ./tools/image_to_terrain.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.dataurl.coffee: %.png ./tools/dataurl.coffee
	@mkdir -p $(@D)
	coffee ./tools/dataurl.coffee $(patsubst %.png,%,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/wave_bumpmap.png: ./tools/mkwave_bumpmap.coffee
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
