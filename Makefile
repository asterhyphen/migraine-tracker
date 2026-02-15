.PHONY: refresh commit

MSG ?=
COMMIT_MSG := $(strip $(if $(MSG),$(MSG),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))))

refresh:
	flutter clean
	flutter pub get

commit:
	@if [ -z "$(COMMIT_MSG)" ]; then \
		echo 'Usage: make commit MSG="your message"'; \
		echo '   or: make commit your-message'; \
		exit 1; \
	fi
	git add .
	git commit -m "$(COMMIT_MSG)"

%:
	@:

push:
	git push origin main