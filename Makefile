HR="=========================================="
SHELL=bash
export PYTHON=python2

all: | build publish

dev: | devbuild devpub

devbuild:
	@echo ${HR}
	@echo "Syncing NPM build deps"
	@echo ${HR}
	npm install uglify-js@1 recess bower coffee-script
	@echo ${HR}
	@echo "Syncing NPM runtime deps"
	@echo ${HR}
	npm update
	@echo ${HR}
	@echo "Syncing local Bower deps"
	@echo ${HR}
	node_modules/bower/bin/bower update
	@echo ${HR}
	@echo "Building Bootstrap"
	@echo ${HR}
	cd components/bootstrap; npm install; $(MAKE) bootstrap
	@echo ${HR}
	@echo "Building jQuery"
	@echo ${HR}
	node_modules/uglify-js/bin/uglifyjs -nc components/jquery/jquery.js > components/jquery/jquery.min.js
	@echo ${HR}
	@echo "Building jQuery Validation"
	@echo ${HR}
	node_modules/uglify-js/bin/uglifyjs -nc components/jquery.validation/jquery.validate.js > components/jquery.validation/jquery-validate.min.js
	@echo ${HR}
	@echo "Building Knockout"
	@echo ${HR}
	cd components/knockout/build; ./build-linux
	node_modules/uglify-js/bin/uglifyjs -nc components/knockout/build/output/knockout-latest.js > components/knockout/build/output/knockout.min.js
	@echo ${HR}
	@echo "Building Knockout-Mapping"
	@echo ${HR}
	cd components/knockout-mapping/build; bash ./build-linux
	node_modules/uglify-js/bin/uglifyjs -nc components/knockout-mapping/build/output/knockout.mapping-latest.js > components/knockout-mapping/build/output/knockout-mapping.min.js

devpub: | clean_pub
	@echo ${HR}
	@echo "Preparing to publish"
	@echo ${HR}
	mkdir -p public/{js,css,img}
	@echo ${HR}
	@echo "Processing coffeescripts"
	@echo ${HR}
	node_modules/coffee-script/bin/coffee -co public/js source/coffee
	@echo ${HR}
	@echo "Publishing Bower components"
	@echo ${HR}
	-cp -f ${PWD}/components/bootstrap/bootstrap/js/*.min.js public/js
	-cp -f ${PWD}/components/bootstrap/bootstrap/css/*.min.css public/css
	-cp -f ${PWD}/components/bootstrap/bootstrap/img/* public/img
	-cp -f ${PWD}/components/knockout/build/output/knockout.min.js public/js
	-cp -f ${PWD}/components/knockout-mapping/build/output/knockout-mapping.min.js public/js
	-cp -f ${PWD}/components/knockout-sortable/build/knockout-sortable.min.js public/js
	-cp -f ${PWD}/components/jquery/jquery.min.js public/js
	-cp -f ${PWD}/components/jquery-ui/ui/minified/jquery-ui.custom.min.js public/js/jquery-ui.min.js
	-cp -f ${PWD}/components/jquery.validation/jquery-validate.min.js public/js
	@echo ${HR}
	@echo "Publishing nTrapy components"
	@echo ${HR}
	-cp -rn ${PWD}/source/ public

build:
	@echo ${HR}
	@echo "Syncing NPM build deps"
	@echo ${HR}
	npm install coffee-script jade
	@echo ${HR}
	@echo "Syncing NPM runtime deps"
	@echo ${HR}
	npm update

publish: | clean_pub
	@echo ${HR}
	@echo "Preparing to deploy"
	@echo ${HR}
	mkdir -p public/{js,css,img}
	@echo ${HR}
	@echo "Deploying Coffeescripts"
	@echo ${HR}
	node_modules/coffee-script/bin/coffee -co public/js source/coffee
	@echo ${HR}
	@echo "Deploying Jade templates"
	@echo ${HR}
	node_modules/jade/bin/jade -o '{title: "OpenCenter"}' views/index.jade --out public
	@echo ${HR}
	@echo "Deploying nTrapy components"
	@echo ${HR}
	-cp -fr source/* public
	@echo ${HR}
	@echo "Scaffolding config file"
	@echo ${HR}
	-mkdir public/api
	-cp config.json.sample public/api/config

deploy:
	HOME=${PWD} $(MAKE)

cert:
	-rm -f *.pem
	openssl genrsa -out key.pem 2048
	openssl req -new -key key.pem -out csr.pem
	openssl x509 -req -in csr.pem -signkey key.pem -out cert.pem
	-rm -f csr.pem

clean: clean_com clean_node clean_pub
	-rm -f *.log
	-rm -f *.db*

clean_com:
	-rm -rf components

clean_node:
	-rm -rf node_modules

clean_pub:
	-rm -rf public
