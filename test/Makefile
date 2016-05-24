DEPS := $(shell ls ../src/*.elm ../src/Native/*.js)

build: test.js test2.js

test.js: Test.elm $(DEPS)
	elm make Test.elm --yes --output=$@

test2.js: Test2.elm $(DEPS)
	elm make Test2.elm --yes --output=$@

