DEPS := $(shell ls ../src/*.elm ../src/Native/*.js)

build: test.js test2.js testConsole

test.js: TestHtml.elm $(DEPS)
	elm make TestHtml.elm --yes --output=$@

test2.js: TestHtml2.elm $(DEPS)
	elm make TestHtml2.elm --yes --output=$@

testConsole:
	./node_modules/.bin/elm-test TestRunnerConsole.elm  --compiler ./node_modules/.bin/elm-make
