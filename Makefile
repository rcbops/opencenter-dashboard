HR="=========================================="
SHELL=bash

all: | clean build link

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

link:
	mkdir -p public/{js,css,img}
	@echo ${HR}
	@echo "Processing coffeescripts"
	@echo ${HR}
	coffee -co source/js source/coffee
	@echo ${HR}
	@echo "Linking Bower components"
	@echo ${HR}
	ln -sf ${PWD}/components/bootstrap/bootstrap/js/*.min.js public/js
	ln -sf ${PWD}/components/bootstrap/bootstrap/css/*.min.css public/css
	ln -sf ${PWD}/components/bootstrap/bootstrap/img/* public/img
	ln -sf ${PWD}/components/knockout/build/output/knockout.min.js public/js
	ln -sf ${PWD}/components/knockout-mapping/build/output/knockout-mapping.min.js public/js
	ln -sf ${PWD}/components/knockout-sortable/build/knockout-sortable.min.js public/js
	ln -sf ${PWD}/components/jquery/jquery.min.js public/js
	@echo ${HR}
	@echo "Linking nTrapy components"
	@echo ${HR}
	ln -sf ${PWD}/source/js/* public/js
	ln -sf ${PWD}/source/css/* public/css

cert:
	rm -f *.pem
	openssl genrsa -out key.pem 2048
	openssl req -new -key key.pem -out csr.pem
	openssl x509 -req -in csr.pem -signkey key.pem -out cert.pem
	rm -f csr.pem

clean:
	rm -rf components node_modules public
	rm -f *.log
