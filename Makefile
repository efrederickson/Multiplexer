ARCHS = armv7 arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachApp
ReachApp_FILES = Tweak.xm
ReachApp_FRAMEWORKS = UIKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 assertiond backboardd"
#	install.exec "killall -9 Preferences"
SUBPROJECTS += reachappsettings
include $(THEOS_MAKE_PATH)/aggregate.mk
