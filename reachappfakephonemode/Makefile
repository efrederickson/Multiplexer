ARCHS = armv7 armv7s arm64

CFLAGS = -I../ -I../Theming

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppFakePhoneMode
ReachAppFakePhoneMode_FILES = Tweak.xm
ReachAppFakePhoneMode_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
