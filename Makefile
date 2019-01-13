ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

SDKVERSION = 6.0

TWEAK_NAME = homeartwork7
homeartwork7_FILES = Tweak.xm
homeartwork7_FRAMEWORKS = UIKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
