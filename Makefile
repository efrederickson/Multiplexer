ARCHS = armv7 armv7s arm64
CFLAGS = -I./ -Iwidgets/ -ISwipeOver/ -IReachability/ -IGestureSupport/ -IKeyboardSupport/ -fobjc-arc
THEOS_PACKAGE_DIR_NAME = debs
TARGET = :clang:8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachApp
ReachApp_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) \
	$(wildcard Reachability/*.xm) $(wildcard Reachability/*.mm) $(wildcard Reachability/*.m) \
	$(wildcard SwipeOver/*.xm) $(wildcard SwipeOver/*.mm) $(wildcard SwipeOver/*.m) \
	$(wildcard widgets/*.xm) $(wildcard widgets/*.mm) $(wildcard widgets/*.m) \
	$(wildcard KeyboardSupport/*.xm) $(wildcard KeyboardSupport/*.mm) $(wildcard KeyboardSupport/*.m) \
	$(wildcard GestureSupport/*.xm) $(wildcard GestureSupport/*.mm) $(wildcard GestureSupport/*.m)
	
ReachApp_FRAMEWORKS = UIKit QuartzCore CoreGraphics 
ReachApp_PRIVATE_FRAMEWORKS = GraphicsServices BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
#	install.exec "killall -9 Preferences"
SUBPROJECTS += reachappsettings
SUBPROJECTS += reachappflipswitch
include $(THEOS_MAKE_PATH)/aggregate.mk
