include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-amneziawg
PKG_VERSION:=1.0.20241119
PKG_RELEASE:=1
WIREGUARD_VERSION:=1.0.0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
PKG_SOURCE_VERSION:=7e7dfca6b2824e5a14c5b011a4e05aac89d85231
PKG_MIRROR_HASH:=skip

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define KernelPackage/amneziawg
	SECTION:=kernel
	CATEGORY:=Kernel modules
	SUBMENU:=Network Support
	TITLE:=AmneziaWG VPN Kernel Module
	FILES:=$(PKG_BUILD_DIR)/$(MAKE_PATH)/generated/amneziawg.ko
	DEPENDS:= \
		+kmod-udptunnel4 \
		+kmod-udptunnel6 \
		+kmod-crypto-lib-chacha20poly1305 \
		+kmod-crypto-lib-curve25519
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	mkdir -p $(PKG_BUILD_DIR)/$(MAKE_PATH)/kernel
	$(CP) $(LINUX_DIR)/* $(PKG_BUILD_DIR)/$(MAKE_PATH)/kernel/
endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR)/$(MAKE_PATH) $(MAKE_FLAGS) apply-patches
	$(MAKE_VARS) $(MAKE) -C "$(LINUX_DIR)" $(KERNEL_MAKE_FLAGS) M="$(PKG_BUILD_DIR)/$(MAKE_PATH)/generated" EXTRA_CFLAGS="$(BUILDFLAGS)" WIREGUARD_VERSION="$(WIREGUARD_VERSION)" modules
endef

$(eval $(call KernelPackage,amneziawg))
