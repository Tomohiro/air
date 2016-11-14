# Project information
OWNER      = $(shell whoami)
TOP        = $(shell pwd)
REPOSITORY = $(shell basename $(TOP))
VERSION    = $(shell grep "const Version " $(TOP)/version.go | sed -E 's/.*"(.+)"$$/\1/')

# Build information
OUTPUT    = $(REPOSITORY)
BUILDDIR  = $(TOP)/pkg
XC_OS     = "darwin linux windows"
XC_ARCH   = "386 amd64"
DISTDIR   = $(BUILDDIR)/dist/$(VERSION)

help:
	@echo "Please type: make [target]"
	@echo "  test         Run tests"
	@echo "  setup        Setup development environment"
	@echo "  install      Build $(OUTPUT) and install to $$GOPATH/bin"
	@echo "  deps         Install runtime dependencies"
	@echo "  updatedeps   Update runtime dependencies"
	@echo "  build        Build $(OUTPUT) in to the pkg directory"
	@echo "  dist         Ship packages to release"
	@echo "  release      Create tag ($(VERSION)) and upload binaries to GitHub"
	@echo "  clean        Cleanup artifacts"
	@echo "  help         Show this help messages"

test: deps
	@echo "===> Running tests..."
	go test -v ./...

setup:
	@echo "===> Setup development tools..."
	# Gox - Simple Go Cross Compilation
	go get -u github.com/mitchellh/gox

	# ghr - Easily ship your project to your user using Github Releases
	go get -u github.com/tcnksm/ghr

install: deps
	@echo "===> Installing '$(OUTPUT)' to $(GOPATH)/bin..."
	go install

deps:
	@echo "===> Installing runtime dependencies..."
	glide install

updatedeps:
	@echo "===> Updating runtime dependencies..."
	glide update

build: deps
	@echo "===> Beginning compile..."
	gox -os $(XC_OS) -arch $(XC_ARCH) -output "pkg/{{.OS}}_{{.Arch}}/$(OUTPUT)"

dist: build
	@echo "===> Shipping packages..."
	rm -rf $(DISTDIR)
	mkdir -p $(DISTDIR)
	@for dir in $$(find $(BUILDDIR) -mindepth 1 -maxdepth 1 -type d); do \
		platform=`basename $$dir`; \
		if [ $$platform = "dist" ]; then \
			continue; \
		fi; \
		archive=$(OUTPUT)_$(VERSION)_$$platform; \
		zip -j $(DISTDIR)/$$archive.zip $$dir/*; \
		pushd $(DISTDIR); \
		shasum -a 256 *.zip > ./$(VERSION)_SHA256SUMS; \
		popd; \
	done

release:
	@echo "===> Publishing to GitHub..."
	ghr -u $(OWNER) -r $(REPOSITORY) $(VERSION) $(DISTDIR)

clean:
	go clean all
	rm -rf $(BUILDDIR)

.PHONY: help test setup deps updatedeps clean release
