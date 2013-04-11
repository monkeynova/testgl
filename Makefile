OUT=build
GENERATED=.generated

EXT_JS=webgl-utils.js jquery-1.9.1.min.js glMatrix-0.9.5.min.js jquery.base64.js

all: $(patsubst %,$(OUT)/%,$(EXT_JS)) $(OUT)/README.html

clean:
	rm -rf $(OUT) $(GENERATED)

neat:
	rm -f *~
	rm -f \#*\#
	rm -f .\#*

include $(GENERATED)/index.jade.d
include $(GENERATED)/code.coffee.d

$(OUT)/README.html: README.md
	@mkdir -p $(@D)
	coffee ./markdown.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.d: % mkdep.coffee
	@mkdir -p $(@D)
	coffee ./mkdep.coffee $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.dataurl.coffee: %.png dataurl.coffee
	@mkdir -p $(@D)
	coffee ./dataurl.coffee $(patsubst %.png,%,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.model.dataurl.coffee: %.model.js dataurl.coffee
	@mkdir -p $(@D)
	jslint $<
	coffee ./dataurl.coffee $(patsubst %.model.js,%_model,$(<F))_data_url $< > $@.tmp
	mv $@.tmp $@

$(GENERATED)/%.skel.dataurl.coffee: %.skel.js dataurl.coffee
	@mkdir -p $(@D)
	jslint $<
	coffee ./dataurl.coffee $(patsubst %.skel.js,%_skel,$(<F))_data_url $< > $@.tmp
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
