ARCHS = arm64 armv7s armv7
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

TWEAK_NAME = MultitaskingGestures
MultitaskingGestures_FILES = GestureSupport.xm OffscreenSwipeRecognizers.xm MoveControlCenter.xm SwitchApp.xm SwipeUp.xm Preferences.m
MultitaskingGestures_FRAMEWORKS = Foundation UIKit CoreGraphics QuartzCore
MultitaskingGestures_PRIVATE_FRAMEWORKS = BackBoardServices
MultitaskingGestures_LDFLAGS += -lMobileGestalt
MultitaskingGestures_CFLAGS += -IHeaders

include $(THEOS_MAKE_PATH)/tweak.mk


SUBPROJECTS += multitaskinggesturessettings
include $(THEOS_MAKE_PATH)/aggregate.mk