ARCHS = armv7 armv7s arm64
CFLAGS = -I../ -I../Theming

include $(THEOS)/makefiles/common.mk

TOOL_NAME = ReachAppFSDaemon
ReachAppFSDaemon_FILES = main.mm
ReachAppFSDaemon_PRIVATE_FRAMEWORKS = Foundation MobileCoreServices

include $(THEOS_MAKE_PATH)/tool.mk
