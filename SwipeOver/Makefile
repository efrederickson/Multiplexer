ARCHS = armv7 armv7s arm64

CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../WindowedMultitasking/ -I../Messaging/ -I../KeyboardSupport -I../MissionControl
CFLAGS += -fobjc-arc
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppSwipeOver
ReachAppSwipeOver_FILES =  $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
ReachAppSwipeOver_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
