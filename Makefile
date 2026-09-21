NAME    = $(shell jq -r '.name | ascii_downcase | gsub("[^a-z0-9]+"; "-")' manifest.json)
VERSION = $(shell jq -r .version manifest.json)
ZIP     = dist/$(NAME)-$(VERSION).zip
FILES   = manifest.json background.js content.js $(wildcard icons/*.png README.md)

CHECK_VERSION = jq -e '.version | test("^(0|[1-9][0-9]{0,4})(\\.(0|[1-9][0-9]{0,4})){0,3}$$") and (split(".") | map(tonumber) | all(. <= 65535) and any(. > 0))' manifest.json >/dev/null \
	|| { echo "manifest.json: invalid version '$$(jq -r .version manifest.json)'" >&2; exit 1; }

.PHONY: build bump clean test

build:
	@$(CHECK_VERSION)
	@rm -rf dist && mkdir dist
	zip -qX -MM $(ZIP) $(FILES)
	@zip -sf $(ZIP)

bump:
	@$(CHECK_VERSION)
	@new=$$(jq -r '.version | split(".") | .[-1] |= (tonumber + 1 | tostring) | join(".")' manifest.json) && \
		sed -i -E 's/("version"[[:space:]]*:[[:space:]]*")[^"]*/\1'"$$new"/ manifest.json
	@$(CHECK_VERSION)
	@echo "$(VERSION) -> $$(jq -r .version manifest.json)"

clean:
	rm -rf dist

test:
	bash tests/package_test.sh
