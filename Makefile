build:
	@jade -P index.jade
	@echo '---\nlayout: none\n---\n' | cat - index.html > temp && mv temp index.html

.PHONY: git
git:
	@echo 'Configuring git'
	@git config --global color.ui true
	@read -r -p "Name ($(GIT_USER_NAME)): " NAME; \
	 if [ ! -z "$$NAME" ]; then \
	   git config --global user.name "$$NAME"; \
	 fi
	@read -r -p "Email ($(GIT_USER_EMAIL)): " EMAIL; \
	 if [ ! -z "$$EMAIL" ]; then \
	   git config --global user.email "$$EMAIL"; \
	 fi
