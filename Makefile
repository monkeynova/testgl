OUT=build

EXT_JS=webgl-utils.js jquery-1.9.1.min.js glMatrix-0.9.5.min.js
COFFEE=code.coffee
JS=$(patsubst %.coffee,%.js,$(COFFEE)) $(EXT_JS)
HTML=index.html

all: $(addprefix $(OUT)/,$(HTML) $(JS))

clean:
	rm -rf $(OUT)

neat:
	rm -f *~

$(OUT)/%.html: %.jade
	@mkdir -p $(@D)
	jade < $< > $@.tmp
	mv $@.tmp $@

$(OUT)/%.js: %.coffee
	@mkdir -p $(@D)
	coffee -p $< > $@.tmp
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
