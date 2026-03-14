include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-amneziawg
PKG_VERSION:=2.0.10
PKG_RELEASE:=1
WIREGUARD_VERSION:=1.0.0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/this-username-has-been-taken/amneziawg-linux-kernel-module.git
# Reference: master branch
PKG_SOURCE_VERSION:=d0e9d12d57064cfffd53b1afeae56615d4c5e929
PKG_MIRROR_HASH:=2593e523b8802b99227bf895c40a1c3f5e152cd31eeebf33afcf23a7a8d4d7db

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define KernelPackage/amneziawg
	SECTION:=kernel
	CATEGORY:=Kernel modules
	SUBMENU:=Network Support
	TITLE:=AmneziaWG VPN Kernel Module
	FILES:=$(PKG_BUILD_DIR)/$(MAKE_PATH)/amneziawg.ko
	DEPENDS:= \
		+kmod-udptunnel4 \
		+kmod-udptunnel6 \
		+kmod-crypto-kpp \
		+kmod-crypto-lib-chacha20poly1305 \
		+kmod-crypto-lib-curve25519
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	mkdir -p $(PKG_BUILD_DIR)/$(MAKE_PATH)/kernel
	$(CP) $(LINUX_DIR)/* $(PKG_BUILD_DIR)/$(MAKE_PATH)/kernel/
endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) -C "$(LINUX_DIR)" $(KERNEL_MAKE_FLAGS) M="$(PKG_BUILD_DIR)/$(MAKE_PATH)" EXTRA_CFLAGS="$(BUILDFLAGS)" WIREGUARD_VERSION="$(WIREGUARD_VERSION)" modules
endef

$(eval $(call KernelPackage,amneziawg))
