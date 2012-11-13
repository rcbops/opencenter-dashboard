HR="=========================================="
SHELL=bash

all: | clean build link

build:
	@echo ${HR}
	@echo "Syncing NPM"
	@echo ${HR}
	npm update
	@echo ${HR}
	@echo "Syncing Bower"
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

link:
	@echo ${HR}
	@echo "Linking Bower components"
	@echo ${HR}
	mkdir -p public/{js,css,img}
	ln -sf ${PWD}/components/bootstrap/bootstrap/js/*.min.js public/js
	ln -sf ${PWD}/components/bootstrap/bootstrap/css/*.min.css public/css
	ln -sf ${PWD}/components/bootstrap/bootstrap/img/* public/img
	ln -sf ${PWD}/components/knockout/build/output/knockout.min.js public/js
	ln -sf ${PWD}/components/jquery/jquery.min.js public/js
	ln -sf ${PWD}/components/d3/d3.v2.min.js public/js/d3.min.js
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
