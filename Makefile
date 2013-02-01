HR="=========================================="
SHELL=bash
export PYTHON=python2

all: | build link

build:
	@echo ${HR}
	@echo "Syncing global NPM deps"
	@echo ${HR}
	npm install -g uglify-js@1 recess anvil.js bower forever coffee-script
	@echo ${HR}
	@echo "Syncing local NPM deps"
	@echo ${HR}
	npm update
	@echo ${HR}
	@echo "Syncing local Bower deps"
	@echo ${HR}
	bower update
	@echo ${HR}
	@echo "Building Bootstrap"
	@echo ${HR}
	cd components/bootstrap; $(MAKE) bootstrap
	@echo ${HR}
	@echo "Building jQuery"
	@echo ${HR}
	uglifyjs -nc components/jquery/jquery.js > components/jquery/jquery.min.js
	@echo ${HR}
	@echo "Building Knockout"
	@echo ${HR}
	cd components/knockout/build; ./build-linux
	uglifyjs -nc components/knockout/build/output/knockout-latest.js > components/knockout/build/output/knockout.min.js
	@echo ${HR}
	@echo "Building Knockout-Mapping"
	@echo ${HR}
	cd components/knockout-mapping/build; bash ./build-linux
	uglifyjs -nc components/knockout-mapping/build/output/knockout.mapping-latest.js > components/knockout-mapping/build/output/knockout-mapping.min.js
	@echo ${HR}
	@echo "Building Knockout-Sortable"
	@echo ${HR}
	cd components/knockout-sortable; anvil

link: | clean_pub
	@echo ${HR}
	@echo "Preparing to link"
	@echo ${HR}
	mkdir -p public/{js,css,img}
	@echo ${HR}
	@echo "Processing coffeescripts"
	@echo ${HR}
	coffee -co public/js source/coffee
	@echo ${HR}
	@echo "Linking Bower components"
	@echo ${HR}
	-ln -s ${PWD}/components/bootstrap/bootstrap/js/*.min.js public/js
	-ln -s ${PWD}/components/bootstrap/bootstrap/css/*.min.css public/css
	-ln -s ${PWD}/components/bootstrap/bootstrap/img/* public/img
	-ln -s ${PWD}/components/knockout/build/output/knockout.min.js public/js
	-ln -s ${PWD}/components/knockout-mapping/build/output/knockout-mapping.min.js public/js
	-ln -s ${PWD}/components/knockout-sortable/build/knockout-sortable.min.js public/js
	-ln -s ${PWD}/components/jquery/jquery.min.js public/js
	-ln -s ${PWD}/components/jquery-ui/ui/minified/jquery-ui.custom.min.js public/js/jquery-ui.min.js
	@echo ${HR}
	@echo "Linking nTrapy components"
	@echo ${HR}
	-ln -s ${PWD}/source/css/* public/css
	-ln -s ${PWD}/source/img/* public/img

deploy: | build link
	@echo ${HR}
	@echo "Building deployment tarball"
	@echo ${HR}
	-rm -f public.tgz
	mkdir -p tmp/public
	-ln -s ../../public/js tmp/public
	-ln -s ../../public/css tmp/public
	-ln -s ../../public/img tmp/public
	node_modules/jade/bin/jade -Do "{title: 'nTrapy'}" views/index.jade --out tmp/public/index.html
	coffee -co tmp/public/js source/coffee
	tar -Lczvf public.tgz -C tmp public
	-rm -f tmp

cert:
	-rm -f *.pem
	openssl genrsa -out key.pem 2048
	openssl req -new -key key.pem -out csr.pem
	openssl x509 -req -in csr.pem -signkey key.pem -out cert.pem
	-rm -f csr.pem

clean: clean_com clean_node clean_pub
	-rm *.log
	-rm *.db*

clean_com:
	-rm -r components

clean_node:
	-rm -r node_modules

clean_pub:
	-pkill -f "coffee -wco public/js source/coffee"
	-rm -r public
