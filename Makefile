include $(TOPDIR)/rules.mk

PKG_NAME:=rm500u-web
PKG_VERSION:=1.0.0
PKG_RELEASE:=8
PKG_LICENSE:=AGPL-3.0-only
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=0

include $(INCLUDE_DIR)/package.mk

# Copy a self-contained linux-musl-x64 publish into payload/ before building.
define Package/rm500u-web
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Quectel RM500U Web management console
  DEPENDS:=@TARGET_x86_64 +libstdcpp +libgcc +libopenssl +zlib +ca-bundle +ip-full +coreutils-stty +luci-base +rpcd +jshn
endef

define Package/rm500u-web/description
  RM500U modem WebUI with a console page under the MiaoWRT LuCI menu. Default port: 5080.
  Default username: admin. Default password: admin.
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/payload
	test -f $(CURDIR)/payload/RM500U.Web
	test -f $(CURDIR)/payload/RM500U.Web.runtimeconfig.json
	test -f $(CURDIR)/payload/wwwroot/index.html
	$(CP) $(CURDIR)/payload/. $(PKG_BUILD_DIR)/payload/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/rm500u-web/conffiles
/etc/config/rm500u-web
/etc/rm500u-web/
endef

define Package/rm500u-web/postinst
#!/bin/sh
# default_postinst only starts services; procd may retain the old executable
# when command arguments are unchanged. Explicitly restart on live upgrades.
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/rpcd reload
	if [ "$${PKG_UPGRADE}" = "1" ]; then
		/etc/init.d/rm500u-web restart
	fi
fi
exit 0
endef

define Package/rm500u-web/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ "$${PKG_UPGRADE}" != "1" ] && [ "$${1}" != "upgrade" ]; then
	/etc/init.d/rm500u-web stop >/dev/null 2>&1 || true
	/etc/init.d/rm500u-web disable >/dev/null 2>&1 || true
fi
exit 0
endef

define Package/rm500u-web/postrm
#!/bin/sh
# APK invokes this only for removal. Keep the guards for opkg and offline builds.
[ -z "$${IPKG_INSTROOT}" ] || exit 0
[ "$${PKG_UPGRADE}" != "1" ] || exit 0
[ "$${1}" != "upgrade" ] || exit 0
rm -f /etc/config/rm500u-web /etc/config/rm500u-web.apk-* /etc/config/rm500u-web-opkg
rm -f /tmp/.uci/rm500u-web /var/state/rm500u-web
rm -f /etc/rc.d/*rm500u-web
rm -rf /etc/rm500u-web /var/lib/rm500u-web /usr/lib/rm500u-web
[ ! -x /etc/init.d/rpcd ] || /etc/init.d/rpcd reload
# Retain the separately imported public signing key for trusted reinstallations.
exit 0
endef

define Package/rm500u-web/install
	$(INSTALL_DIR) $(1)/usr/lib/rm500u-web $(1)/etc/init.d $(1)/etc/config $(1)/etc/rm500u-web
	$(CP) $(PKG_BUILD_DIR)/payload/. $(1)/usr/lib/rm500u-web/
	printf '%s\n' '$(PKG_VERSION)-r$(PKG_RELEASE)' > $(1)/usr/lib/rm500u-web/package-version
	# Optional LTTng provider requires libraries not shipped by OpenWrt.
	rm -f $(1)/usr/lib/rm500u-web/libcoreclrtraceptprovider.so
	# .NET uses Alpine's musl SONAME; OpenWrt names the same libc libc.so.
	ln -sf /lib/libc.so $(1)/usr/lib/rm500u-web/libc.musl-x86_64.so.1
	$(CP) ./files/luci/. $(1)/
	$(INSTALL_BIN) ./files/rm500u-web.init $(1)/etc/init.d/rm500u-web
	$(INSTALL_CONF) ./files/rm500u-web.config $(1)/etc/config/rm500u-web
	chmod 0700 $(1)/etc/rm500u-web
endef

$(eval $(call BuildPackage,rm500u-web))
