build: install compile

.PHONY: install
install:
	@git submodule update --init

.PHONY: compile
compile:
	@lessc -x css/shuttle.less > css/shuttle.css
	@jade -P index.jade
	@echo '---\nlayout: none\n---\n' | cat - index.html > temp && mv temp index.html

.PHONY: serve
serve: compile
	@jekyll serve
