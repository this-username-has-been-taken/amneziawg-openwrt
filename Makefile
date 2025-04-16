#!/usr/bin/env make -f

SELF := $(abspath $(lastword $(MAKEFILE_LIST)))
TOPDIR := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
UPPERDIR := $(realpath $(TOPDIR)/../)

OPENWRT_SRCDIR   ?= $(UPPERDIR)/openwrt
AMNEZIAWG_SRCDIR ?= $(TOPDIR)
AMNEZIAWG_DSTDIR ?= $(UPPERDIR)/awgrelease

OPENWRT_RELEASE   ?= SNAPSHOT
OPENWRT_ARCH      ?= aarch64_cortex-a53
OPENWRT_TARGET    ?= mediatek
OPENWRT_SUBTARGET ?= filogic
OPENWRT_VERMAGIC  ?= any

GITHUB_SHA        ?= $(shell git rev-parse --short HEAD)
VERSION_STR       ?= $(shell git describe --tags --long --dirty)
POSTFIX           := $(OPENWRT_RELEASE)_$(OPENWRT_ARCH)_$(OPENWRT_TARGET)_$(OPENWRT_SUBTARGET)
POSTFIX_RELEASE   := $(GITHUB_REF_NAME)_$(OPENWRT_RELEASE)_$(OPENWRT_ARCH)_$(OPENWRT_TARGET)_$(OPENWRT_SUBTARGET)

WORKFLOW_REF      ?= $(shell git rev-parse --abbrev-ref HEAD)
FINAL_VERMAGIC    := $(shell cat $(OPENWRT_SRCDIR)/build_dir/target-$(OPENWRT_ARCH)*/linux-$(OPENWRT_TARGET)_$(OPENWRT_SUBTARGET)/linux-*/.vermagic)

NPROC ?= $(shell getconf _NPROCESSORS_ONLN)

ifndef OPENWRT_VERMAGIC
	_NEED_VERMAGIC=1
endif

ifeq ($(OPENWRT_VERMAGIC), auto)
	_NEED_VERMAGIC=1
endif

ifeq ($(OPENWRT_RELEASE), SNAPSHOT)
	OPENWRT_ROOT_URL := https://downloads.openwrt.org/snapshots
	OPENWRT_BASE_URL := $(OPENWRT_ROOT_URL)/targets/$(OPENWRT_TARGET)/$(OPENWRT_SUBTARGET)
	OPENWRT_MANIFEST := $(OPENWRT_BASE_URL)/openwrt-$(OPENWRT_TARGET)-$(OPENWRT_SUBTARGET).manifest
	GIT_BRANCH := master
	ifeq ($(_NEED_VERMAGIC), 1)
		OPENWRT_VERMAGIC := $(shell curl -fs $(OPENWRT_MANIFEST) | grep -- "^kernel" | sed -e "s/.*~//;s/-.*//")
	endif
else
	OPENWRT_ROOT_URL := https://downloads.openwrt.org/releases
	OPENWRT_BASE_URL := $(OPENWRT_ROOT_URL)/$(OPENWRT_RELEASE)/targets/$(OPENWRT_TARGET)/$(OPENWRT_SUBTARGET)
	OPENWRT_MANIFEST := $(OPENWRT_BASE_URL)/openwrt-$(OPENWRT_RELEASE)-$(OPENWRT_TARGET)-$(OPENWRT_SUBTARGET).manifest
	GIT_BRANCH := v$(OPENWRT_RELEASE)
	ifeq ($(_NEED_VERMAGIC), 1)
		OPENWRT_VERMAGIC := $(shell curl -fs $(OPENWRT_MANIFEST) | grep -- "^kernel" | sed -e "s,.*\-,,")
	endif
endif

help: ## Show help message (list targets)
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(SELF)

SHOW_ENV_VARS = \
	SHELL \
	SELF \
	TOPDIR \
	UPPERDIR \
	OPENWRT_SRCDIR \
	AMNEZIAWG_SRCDIR \
	AMNEZIAWG_DSTDIR \
	GITHUB_SHA \
	VERSION_STR \
	POSTFIX \
	GITHUB_REF_TYPE \
	GITHUB_REF_NAME \
	WORKFLOW_REF \
	OPENWRT_RELEASE \
	OPENWRT_ARCH \
	OPENWRT_TARGET \
	OPENWRT_SUBTARGET \
	OPENWRT_VERMAGIC \
	OPENWRT_BASE_URL \
	OPENWRT_MANIFEST \
	NPROC \
	FINAL_VERMAGIC

show-var-%:
	@{ \
	escaped_v="$(subst ",\",$($*))" ; \
	if [ -n "$$escaped_v" ]; then v="$$escaped_v"; else v="(undefined)"; fi; \
	printf "%-21s %s\n" "$*" "$$v"; \
	}

show-env: $(addprefix show-var-, $(SHOW_ENV_VARS)) ## Show environment details

export-var-%:
	@{ \
	escaped_v="$(subst ",\",$($*))" ; \
	if [ -n "$$escaped_v" ]; then v="$$escaped_v"; else v="(undefined)"; fi; \
	printf "%s=%s\n" "$*" "$$v"; \
	}

export-env: $(addprefix export-var-, $(SHOW_ENV_VARS)) ## Export environment

.PHONY: github-build-cache
github-build-cache: ## Run GitHub workflow to create OpenWrt toolchain and kernel cache (use WORKFLOW_REF to specify branch/tag)
	@{ \
	set -ex ; \
	gh workflow run build-toolchain-cache.yml \
		--ref $(WORKFLOW_REF) \
		-f openwrt_version=$(OPENWRT_RELEASE) \
		-f openwrt_arch=$(OPENWRT_ARCH) \
		-f openwrt_target=$(OPENWRT_TARGET) \
		-f openwrt_subtarget=$(OPENWRT_SUBTARGET) \
		-f openwrt_vermagic=$(OPENWRT_VERMAGIC) ; \
	}

.PHONY: github-build-artifacts
github-build-artifacts: ## Run GitHub workflow to build amneziawg OpenWrt packages (use WORKFLOW_REF to specify branch/tag)
	@{ \
	set -ex ; \
	gh workflow run build-module-artifacts.yml \
		--ref $(WORKFLOW_REF) \
		-f openwrt_version=$(OPENWRT_RELEASE) \
		-f openwrt_arch=$(OPENWRT_ARCH) \
		-f openwrt_target=$(OPENWRT_TARGET) \
		-f openwrt_subtarget=$(OPENWRT_SUBTARGET) \
		-f openwrt_vermagic=$(OPENWRT_VERMAGIC) ; \
	}

$(OPENWRT_SRCDIR):
	@{ \
	set -ex ; \
	git clone https://github.com/openwrt/openwrt.git $@ ; \
	cd $@ ; \
	git checkout $(GIT_BRANCH) ; \
	}

$(OPENWRT_SRCDIR)/feeds.conf: | $(OPENWRT_SRCDIR)
	@{ \
	set -ex ; \
	curl -fsL $(OPENWRT_BASE_URL)/feeds.buildinfo | tee $@ ; \
	}

$(OPENWRT_SRCDIR)/.config: | $(OPENWRT_SRCDIR)
	@{ \
	set -ex ; \
	curl -fsL $(OPENWRT_BASE_URL)/config.buildinfo > $@ ; \
	echo "CONFIG_PACKAGE_kmod-crypto-lib-chacha20=m" >> $@ ; \
	echo "CONFIG_PACKAGE_kmod-crypto-lib-chacha20poly1305=m" >> $@ ; \
	echo "CONFIG_PACKAGE_kmod-crypto-chacha20poly1305=m" >> $@ ; \
	}

.PHONY: build-toolchain
build-toolchain: $(OPENWRT_SRCDIR)/feeds.conf $(OPENWRT_SRCDIR)/.config ## Build OpenWrt toolchain
	@{ \
	set -ex ; \
	cd $(OPENWRT_SRCDIR) ; \
	time -p ./scripts/feeds update ; \
	time -p ./scripts/feeds install -a ; \
	time -p make defconfig ; \
	time -p make tools/install -i -j $(NPROC) ; \
	time -p make toolchain/install -i -j $(NPROC) ; \
	}

.PHONY: build-kernel
build-kernel: $(OPENWRT_SRCDIR)/feeds.conf $(OPENWRT_SRCDIR)/.config ## Build OpenWrt kernel
	@{ \
	set -ex ; \
	cd $(OPENWRT_SRCDIR) ; \
	time -p make defconfig ; \
	time -p make V=s target/linux/compile -i -j $(NPROC) ; \
	VERMAGIC=$$(cat ./build_dir/target-$(OPENWRT_ARCH)*/linux-$(OPENWRT_TARGET)_$(OPENWRT_SUBTARGET)/linux-*/.vermagic) ; \
	echo "Vermagic: $${VERMAGIC}" ; \
	if [ "$(OPENWRT_VERMAGIC)" != "any" ] && [ "$${VERMAGIC}" != "$(OPENWRT_VERMAGIC)" ]; then \
		echo "Vermagic mismatch: $${VERMAGIC}, expected $(OPENWRT_VERMAGIC)" ; \
		exit 1 ; \
	fi ; \
	}

# TODO: this should not be required but actions/cache/save@v4 could not handle circular symlinks with error like this:
# Warning: ELOOP: too many symbolic links encountered, stat '/home/runner/work/amneziawg-openwrt/amneziawg-openwrt/openwrt/staging_dir/toolchain-mips_24kc_gcc-11.2.0_musl/initial/lib/lib'
# Warning: Cache save failed.
.PHONY: purge-circular-symlinks
purge-circular-symlinks:
	@{ \
	set -ex ; \
	cd $(OPENWRT_SRCDIR) ; \
	export LC_ALL=C ; \
	for deadlink in $$(find . -follow -type l -printf "" 2>&1 | sed -e "s/find: '\(.*\)': Too many levels of symbolic links.*/\1/"); do \
		echo "deleting dead link: $${deadlink}" ; \
		rm -f "$${deadlink}" ; \
	done ; \
	}

.PHONY: build-amneziawg
build-amneziawg: ## Build amneziawg-openwrt kernel module and packages
	@{ \
	set -ex ; \
	cd $(OPENWRT_SRCDIR) ; \
	VERMAGIC=$$(cat ./build_dir/target-$(OPENWRT_ARCH)*/linux-$(OPENWRT_TARGET)_$(OPENWRT_SUBTARGET)/linux-*/.vermagic) ; \
	echo "Vermagic: $${VERMAGIC}" ; \
	if [ "$(OPENWRT_VERMAGIC)" != "any" ] && [ "$${VERMAGIC}" != "$(OPENWRT_VERMAGIC)" ]; then \
		echo "Vermagic mismatch: $${VERMAGIC}, expected $(OPENWRT_VERMAGIC)" ; \
		exit 1 ; \
	fi ; \
	mv feeds.conf feeds.conf.bak ; \
	echo "src-git packages https://git.openwrt.org/feed/packages.git" >> feeds.conf ; \
	echo "src-git luci https://git.openwrt.org/project/luci.git" >> feeds.conf ; \
	echo "src-git routing https://git.openwrt.org/feed/routing.git" >> feeds.conf ; \
	echo "src-git telephony https://git.openwrt.org/feed/telephony.git" >> feeds.conf ; \
	echo "src-cpy awgopenwrt $(AMNEZIAWG_SRCDIR)" >> feeds.conf ; \
	./scripts/feeds update ; \
	./scripts/feeds install -a ; \
	mv .config.old .config ; \
	echo "CONFIG_PACKAGE_kmod-amneziawg=m" >> .config ; \
	echo "CONFIG_PACKAGE_amneziawg-tools=y" >> .config ; \
	echo "CONFIG_PACKAGE_luci-proto-amneziawg=y" >> .config ; \
	make defconfig ; \
	make V=s package/kmod-amneziawg/clean ; \
	make V=s package/kmod-amneziawg/download ; \
	make V=s package/kmod-amneziawg/prepare ; \
	make V=s package/kmod-amneziawg/compile ; \
	make V=s package/luci-proto-amneziawg/clean ; \
	make V=s package/luci-proto-amneziawg/download ; \
	make V=s package/luci-proto-amneziawg/prepare ; \
	make V=s package/luci-proto-amneziawg/compile ; \
	make V=s package/amneziawg-tools/clean ; \
	make V=s package/amneziawg-tools/download ; \
	make V=s package/amneziawg-tools/prepare ; \
	make V=s package/amneziawg-tools/compile ; \
	}

.PHONY: prepare-artifacts
prepare-artifacts: ## Save amneziawg-openwrt artifacts from regular builds
	@{ \
	set -ex ; \
	cd $(OPENWRT_SRCDIR) ; \
	VERMAGIC=$$(cat ./build_dir/target-$(OPENWRT_ARCH)*/linux-$(OPENWRT_TARGET)_$(OPENWRT_SUBTARGET)/linux-*/.vermagic) ; \
	echo "Vermagic: $${VERMAGIC}" ; \
	mkdir -p $(AMNEZIAWG_DSTDIR) ; \
	cp bin/packages/$(OPENWRT_ARCH)/awgopenwrt/amneziawg-tools_*.ipk $(AMNEZIAWG_DSTDIR)/amneziawg-tools_$(POSTFIX)_$${VERMAGIC}.ipk ; \
	cp bin/packages/$(OPENWRT_ARCH)/awgopenwrt/luci-proto-amneziawg_*.ipk $(AMNEZIAWG_DSTDIR)/luci-proto-amneziawg_$(POSTFIX)_$${VERMAGIC}.ipk ; \
	cp bin/targets/$(OPENWRT_TARGET)/$(OPENWRT_SUBTARGET)/packages/kmod-amneziawg_*.ipk $(AMNEZIAWG_DSTDIR)/kmod-amneziawg_$(POSTFIX)_$${VERMAGIC}.ipk ; \
	}

.PHONY: check-release
check-release: ## Verify that everything is in place for tagged release
	@{ \
	set -eux ; \
	echo "checking for release" ; \
	if [ "$${GITHUB_REF_TYPE}" != "tag" ]; then \
		echo "ERROR: unsupported GITHUB_REF_TYPE: $${GITHUB_REF_TYPE}" >&2 ; \
		exit 1 ; \
	fi ; \
	if ! echo "$${GITHUB_REF_NAME}" | grep -q -E '^v[0-9]+(\.[0-9]+){2}$$'; then \
		echo "ERROR: tag $${GITHUB_REF_NAME} is NOT a valid semver" >&2 ; \
		exit 1 ; \
	fi ; \
	num_extra_commits="$$(git rev-list "$${GITHUB_REF_NAME}..HEAD" --count)" ; \
	if [ "$${num_extra_commits}" -gt 0 ]; then \
		echo "ERROR: $${num_extra_commits} extra commit(s) detected" >&2 ; \
		exit 1 ; \
	fi ; \
	}

.PHONY: prepare-release
prepare-release: check-release ## Save amneziawg-openwrt artifacts from tagged release
	@{ \
	set -ex ; \
	cd $(OPENWRT_SRCDIR) ; \
	mkdir -p $(AMNEZIAWG_DSTDIR) ; \
	cp bin/packages/$(OPENWRT_ARCH)/awgopenwrt/amneziawg-tools_*.ipk $(AMNEZIAWG_DSTDIR)/amneziawg-tools_$(POSTFIX_RELEASE).ipk ; \
	cp bin/packages/$(OPENWRT_ARCH)/awgopenwrt/luci-proto-amneziawg_*.ipk $(AMNEZIAWG_DSTDIR)/luci-proto-amneziawg_$(POSTFIX_RELEASE).ipk ; \
	cp bin/targets/$(OPENWRT_TARGET)/$(OPENWRT_SUBTARGET)/packages/kmod-amneziawg_*.ipk $(AMNEZIAWG_DSTDIR)/kmod-amneziawg_$(POSTFIX_RELEASE).ipk ; \
	}
