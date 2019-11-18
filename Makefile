all:
	rm -rf speech
	mkdir -p speech
	cp manifest.json css/* html/* lib/* speech/
	cp -R _locales speech/
	cp images/mic*.png speech/
	npm install
	cd coffee && npx coffee -o ../speech -c *.coffee
	zip -9 -r -X speech-0.8.zip speech
