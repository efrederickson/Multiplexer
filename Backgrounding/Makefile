ARCHS = armv7 armv7s arm64

CFLAGS = -I../ -I../Theming/
CFLAGS += -fno-objc-arc
LDFLAGS += -Wl,-segalign,4000

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppBackgrounding
ReachAppBackgrounding_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) ../Tweak.xm
ReachAppBackgrounding_FRAMEWORKS = UIKit CoreGraphics
ReachAppBackgrounding_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
