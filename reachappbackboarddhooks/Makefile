ARCHS = armv7 armv7s arm64
CFLAGS = -I../Messaging/

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppBackboarddHooks
ReachAppBackboarddHooks_FILES = Tweak.xm
ReachAppBackboarddHooks_LIBRARIES = IOKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
