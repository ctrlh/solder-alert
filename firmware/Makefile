# Build helpers for the Solder Alert firmware.
#
# Dev builds stamp fw_version from git as dev-<commits-since-tag>-g<shortsha>
# (e.g. dev-3-gab12c4), so a `make` build is always traceable to a commit
# and never looks like a release. Releases use YYYY.MMDD.NN (NN = the day's
# release counter) and are stamped by the /release runbook from tags — not
# here. Before the first tag exists, falls back to dev-<total-commits>-g<sha>.
# The ESPHome yaml keeps a default of "dev" so `esphome run ...` directly
# still works without a version override.
FW_VERSION := $(shell \
	d=$$(git describe --tags --long 2>/dev/null); \
	if [ -n "$$d" ]; then \
		printf '%s' "$$d" | sed -E 's/^[^-]+-/dev-/'; \
	else \
		printf 'dev-%s-g%s' \
			"$$(git rev-list --count HEAD 2>/dev/null || echo 0)" \
			"$$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"; \
	fi)

# Auto-pick the first USB modem port; override with `make monitor DEVICE=/dev/...`
DEVICE ?= $(shell ls -1 /dev/cu.usbmodem* 2>/dev/null | head -1)

# Board variant selects the entrypoint file solder-alert-<board>.yaml.
# Override: `make run BOARD=s3`. Default is the C6 hardware.
BOARD ?= c6
YAML := solder-alert-$(BOARD).yaml

.DEFAULT_GOAL := help
.PHONY: help run compile upload logs monitor config clean clean-all

help: ## Show this help
	@echo "Solder Alert firmware — make targets:"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "  board / entrypoint:                $(BOARD) → $(YAML)"
	@echo "  fw_version stamp for this session: $(FW_VERSION)"
	@echo "  USB device auto-detected:          $(if $(DEVICE),$(DEVICE),(none — override with DEVICE=/dev/...))"

# run is now upload + monitor. monitor auto-reconnects when the
# post-upload reset drops USB-JTAG, so the boot log is captured.
run: upload monitor ## Compile + flash + auto-monitor (Ctrl+C to exit monitor)

compile: ## Compile only
	esphome -s fw_version $(FW_VERSION) compile $(YAML)

upload: ## Compile + flash without attaching logs
	esphome -s fw_version $(FW_VERSION) run --no-logs $(YAML) $(if $(DEVICE), --device $(DEVICE), )

logs: ## Attach logs (one-shot; exits on serial disconnect)
	esphome logs $(YAML) $(if $(DEVICE), --device $(DEVICE), )

# ESP32-C6 USB-JTAG reset tears down the CDC endpoint, so `esphome
# logs` bails with "Serial port closed!". Wrap it in a reconnect
# loop so the boot log is captured after every reset.
monitor: ## Attach logs with auto-reconnect on USB reset (Ctrl+C to exit)
	@if [ -z "$(DEVICE)" ]; then \
		echo "No USB modem device found under /dev/cu.usbmodem*."; \
		echo "Plug the board in or pass DEVICE=/dev/... explicitly."; \
		exit 1; \
	fi
	@echo ">>> Log stream on $(DEVICE) — press RESET on the board for a fresh boot. Ctrl+C to exit."
	@while :; do \
		esphome logs $(YAML) --device $(DEVICE) 2>&1 || true; \
		echo ">>> Reconnecting to $(DEVICE)..."; \
		sleep 0.5; \
	done

config: ## Validate config with the version stamp applied
	esphome -s fw_version $(FW_VERSION) config $(YAML)

# ESPHome caches the validated config in .esphome/storage/*.yaml.json
# and *.validated.yaml. When it uses the cache it skips re-rendering
# main.cpp, so subsequent runs may flash a stale binary even after
# yaml edits. Invalidating just those two files (plus the generated
# main.cpp for good measure) forces a re-render + incremental
# recompile without touching the toolchain / framework / lib caches.
# This is a workaround for esphome/feature-requests#2171; if the
# cache invalidation approach ever gets fixed upstream this target
# becomes redundant.
clean: ## Invalidate ESPHome config cache (force yaml re-render + incremental rebuild)
	rm -f .esphome/storage/$(YAML).json
	rm -f .esphome/storage/$(YAML).validated.yaml
	rm -f .esphome/build/solder-alert/src/main.cpp

clean-all: ## Nuke all build state including PlatformIO caches (slow to recover — only when 'clean' isn't enough)
	esphome clean $(YAML)
