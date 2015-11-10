IMAGE := pyramid
EXPRESSION := pyramid.nix

DOCKER := docker
BUILDER_CONTAINER := nix-builder
DATA_CONTAINER := nix-store
BUILD_OPTIONS := --rm=true --force-rm=true --no-cache=true

IF_STORE = $(DOCKER) ps -a | grep $(DATA_CONTAINER) &&
IF_BUILDER = $(DOCKER) images | grep $(BUILDER_CONTAINER) &&
IF_IMAGE = $(DOCKER) images | grep $(IMAGE) &&

IF_NOT_STORE = $(DOCKER) ps -a | grep $(DATA_CONTAINER) ||
IF_NOT_BUILDER = $(DOCKER) images | grep $(BUILDER_CONTAINER) ||

MAKE_IMAGE := .sentinel.image
MAKE_BUILDER := .sentinel.builder

run: $(MAKE_IMAGE)
	$(DOCKER) run --rm -v $(PWD):/mnt -w /mnt -P $(IMAGE) hello_world.py

image: $(MAKE_IMAGE)
	@:

$(MAKE_IMAGE): Dockerfile $(EXPRESSION).tar.gz
	$(DOCKER) build -t $(IMAGE) $(BUILD_OPTIONS) .
	@touch $(MAKE_IMAGE)

$(EXPRESSION).tar.gz: $(EXPRESSION) $(MAKE_BUILDER)
	$(IF_NOT_STORE) $(DOCKER) create --name $(DATA_CONTAINER) $(BUILDER_CONTAINER)
	$(DOCKER) run --rm --volumes-from=$(DATA_CONTAINER) -v $(PWD):/mnt \
		$(BUILDER_CONTAINER) /mnt/$(EXPRESSION)

builder: $(MAKE_BUILDER)
	@:

$(MAKE_BUILDER): nix-builder.docker nix-builder.sh
	$(IF_NOT_BUILDER) $(DOCKER) build -t $(BUILDER_CONTAINER) -f nix-builder.docker $(BUILD_OPTIONS) .
	@touch $(MAKE_BUILDER)

clean:
	$(IF_STORE) $(DOCKER) rm --volumes=true $(DATA_CONTAINER) || true
	$(IF_BUILDER) $(DOCKER) rmi --force=true $(BUILDER_CONTAINER) || true
	$(IF_IMAGE) $(DOCKER) rmi --force=true $(IMAGE) || true
	@rm -f $(MAKE_IMAGE) $(MAKE_BUILDER)

.PHONY: run image builder clean
