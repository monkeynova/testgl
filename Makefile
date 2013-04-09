OUT=build
GENERATED=.generated

EXT_JS=webgl-utils.js jquery-1.9.1.min.js glMatrix-0.9.5.min.js
COFFEE=code.coffee
JS=$(patsubst %.coffee,%.js,$(COFFEE)) $(EXT_JS)
HTML=index.html

all: html js

html: $(addprefix $(OUT)/,$(HTML))
js: $(addprefix $(OUT)/,$(JS)) 

clean:
	rm -rf $(OUT)

neat:
	rm -f *~
	rm -f \#*\#
	rm -f .\#*

$(OUT)/%.html: %.jade
	@mkdir -p $(@D)
	jade -p . < $< > $@.tmp
	mv $@.tmp $@

$(OUT)/index.html: shader.frag shader.vert

$(GENERATED)/code.coffee: code.coffee shaders.coffee shapes.coffee $(GENERATED)/texture.coffee
	@mkdir -p $(@D)
	coffeescript-concat -I . -I $(GENERATED) -o $@.tmp $<
	mv $@.tmp $@

$(GENERATED)/texture.coffee: texture.png dataurl.coffee
	@mkdir -p $(@D)
	coffee ./dataurl.coffee texture_data_url texture.png > $@.tmp
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
