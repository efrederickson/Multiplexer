ARCHS = armv7 armv7s arm64

CFLAGS = -I../ -I../Theming/ -I../GestureSupport/ -I../WindowedMultitasking/
CFLAGS += -fobjc-arc
LDFLAGS += -Wl,-segalign,4000

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppMissionControl
ReachAppMissionControl_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m)
ReachAppMissionControl_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
