include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-amneziawg
PKG_VERSION:=1.0.20260210
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define KernelPackage/amneziawg
SECTION:=kernel
CATEGORY:=Kernel modules
SUBMENU:=Network Support
TITLE:=AmneziaWG VPN Kernel Module
VERSION:=$(PKG_VERSION)-$(LINUX_VERSION)
FILES:=$(PKG_BUILD_DIR)/$(MAKE_PATH)/amneziawg.ko
DEPENDS:=+kmod-udptunnel4 +kmod-udptunnel6 +kmod-crypto-kpp +kmod-crypto-lib-chacha20poly1305 +kmod-crypto-lib-curve25519
endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) -C "$(LINUX_DIR)" \
	$(KERNEL_MAKE_FLAGS) \
	M="$(PKG_BUILD_DIR)/$(MAKE_PATH)" \
	EXTRA_CFLAGS="$(BUILDFLAGS)" \
	modules
endef

$(eval $(call KernelPackage,amneziawg))
