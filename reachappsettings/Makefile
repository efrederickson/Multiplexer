ARCHS = armv7 armv7s arm64
TARGET = iPhone:clang:latest:latest
CFLAGS = -fobjc-arc -I../ -I../Backgrounding/ -I../Theming/ -I../NotificationCenterApp
LDFLAGS = -F$(THEOS)/frameworks
LDFLAGS += -Wl,-segalign,4000

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ReachAppSettings
ReachAppSettings_FILES = ReachAppSettings.mm $(shell find $(THEOS)/include/SettingsKit -name '*.m') $(wildcard *.xm) RAHeaderView.mm ../PDFImageOptions.m ../PDFImage.m ../RALocalizer.mm ../RASettings.mm $(wildcard ../Theming/*.mm) 
ReachAppSettings_INSTALL_PATH = /Library/PreferenceBundles
ReachAppSettings_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics
ReachAppSettings_LIBRARIES = applist substrate
ReachAppSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)rsync -a -v --ignore-existing $(THEOS)/include/SettingsKit/Resources/*.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/ReachAppSettings.bundle/$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ReachAppSettings.plist$(ECHO_END)
