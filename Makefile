NAME    = $(shell jq -r '.name | ascii_downcase | gsub("[^a-z0-9]+"; "-")' manifest.json)
VERSION = $(shell jq -r .version manifest.json)
ZIP     = dist/$(NAME)-$(VERSION).zip
FILES   = manifest.json background.js content.js $(wildcard icons/*.png README.md)

CHECK_VERSION = jq -e '.version | test("^(0|[1-9][0-9]{0,4})(\\.(0|[1-9][0-9]{0,4})){0,3}$$") and (split(".") | map(tonumber) | all(. <= 65535) and any(. > 0))' manifest.json >/dev/null \
	|| { echo "manifest.json: invalid version '$$(jq -r .version manifest.json)'" >&2; exit 1; }

.PHONY: build clean

build:
	@$(CHECK_VERSION)
	@rm -rf dist && mkdir dist
	zip -qX -MM $(ZIP) $(FILES)
	@zip -sf $(ZIP)

clean:
	rm -rf dist
