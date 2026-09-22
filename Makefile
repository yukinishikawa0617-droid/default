.PHONY: setup check lint test fmt
setup: ; @scripts/setup.sh
check: ; @scripts/check.sh all
lint:  ; @scripts/check.sh lint
test:  ; @scripts/check.sh test
fmt:   ; @scripts/check.sh fmt
