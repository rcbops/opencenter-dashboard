HR="=========================================="

build:
	@echo ${HR}
	@echo "Syncing NPM"
	@echo ${HR}
	@npm update
	@echo ${HR}
	@echo "Syncing Bower"
	@echo ${HR}
	@bower update
	@echo ${HR}
	@echo "Building Bootstrap"
	@echo ${HR}
	@cd components/bootstrap; $(MAKE) bootstrap
	@cp -a components/bootstrap/bootstrap/js/*.min.js public/js
	@cp -a components/bootstrap/bootstrap/css/*.min.css public/css
	@cp -a components/bootstrap/bootstrap/img/* public/img
	@echo ${HR}
	@echo "Building jQuery"
	@echo ${HR}
	@uglifyjs -nc components/jquery/jquery.js > public/js/jquery.min.js
	@echo ${HR}
	@echo "Building Knockout"
	@echo ${HR}
	@cd components/knockout/build; ./build-linux
	@uglifyjs -nc components/knockout/build/output/knockout-latest.js > public/js/knockout.min.js

cert:
	@openssl genrsa -out key.pem 2048
	@openssl req -new -key key.pem -out csr.pem
	@openssl x509 -req -in csr.pem -signkey key.pem -out cert.pem
	@rm csr.pem
