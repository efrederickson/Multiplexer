ARCHS = armv7 armv7s arm64
CFLAGS = -I./ -Iwidgets/
THEOS_PACKAGE_DIR_NAME = debs

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachApp
ReachApp_FILES = Tweak.xm RASettings.mm \
	RAWidgetSection.mm RAWidgetSectionManager.mm RAWidget.mm RAReachabilityManager.mm \
	widgets/RADefaultWidgetSection.mm widgets/RAAllAppsWidget.xm widgets/RARecentAppsWidget.xm widgets/RAFavoriteAppsWidget.xm
ReachApp_FRAMEWORKS = UIKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
#	install.exec "killall -9 Preferences"
SUBPROJECTS += reachappsettings
SUBPROJECTS += reachappflipswitch
include $(THEOS_MAKE_PATH)/aggregate.mk
