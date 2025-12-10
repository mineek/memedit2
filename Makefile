CC = xcrun -sdk iphoneos clang
TARGET_SYSROOT := $(shell xcrun -sdk iphoneos --show-sdk-path)
CFLAGS = -isysroot $(TARGET_SYSROOT) -arch arm64 -Wno-error -Oz -flto=full -miphoneos-version-min=14.0 -std=gnu17 -fvisibility=hidden
LDFLAGS = -isysroot $(TARGET_SYSROOT) -arch arm64 -Wl,-dead_strip

ifdef RELEASE_BUILD
	CFLAGS += -DRELEASE_BUILD
	LDFLAGS += -Wl,-x -Wl,-S
else
	CFLAGS += -DREMOTE_LOG_IP='"192.168.3.3"'
endif

C_SRCS = $(shell find mem memui il2cpp -type f -name '*.c')
CFLAGS += $(addprefix -I, $(shell find mem memui -type d))

OBJC_SRCS = $(shell find mem memui il2cpp -type f -name '*.m')
OBJC_SRCS += Tweak.m
OBJCFLAGS = -fobjc-arc

OBJDIR = obj
OBJS = $(patsubst %,$(OBJDIR)/%,$(OBJC_SRCS:.m=.m.o) $(C_SRCS:.c=.c.o))
# $(error OBJS = $(OBJS))

LIBS = -lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics

TARGET_TEST_APP = /Users/mineek/Library/Containers/io.playcover.PlayCover/Applications/eu.bandainamcoent.pacman256.app/PAC-MAN256
TARGET_TEST_APP_ROOT = $(shell dirname $(TARGET_TEST_APP))

all: memedit.dylib

.PHONY: all clean

memedit.dylib: $(OBJS)
	@mkdir -p $(OBJDIR)
	@echo "LD $@"
	@$(CC) $(CFLAGS) $(LDFLAGS) -shared -o $@ $^ $(LIBS)
	@echo "SIGN $@"
	@codesign -f -s - $@

$(OBJDIR)/%.m.o: %.m
	@mkdir -p $(dir $@)
	@echo "CC $<"
	@$(CC) $(CFLAGS) $(OBJCFLAGS) -c $< -o $@

$(OBJDIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	@echo "CC $<"
	@$(CC) $(CFLAGS) -c $< -o $@

testinjectprep: insert_dylib
	./tools/insert_dylib "@executable_path/memedit.dylib" $(TARGET_TEST_APP) --inplace
	ldid -e $(TARGET_TEST_APP) > entitlements.xml
	codesign -f -s - --entitlements entitlements.xml $(TARGET_TEST_APP)
	rm entitlements.xml

testinject: memedit.dylib
	cp memedit.dylib $(TARGET_TEST_APP_ROOT)/memedit.dylib
	vtool -set-build-version 6 15 15 -replace -output $(TARGET_TEST_APP_ROOT)/memedit.dylib $(TARGET_TEST_APP_ROOT)/memedit.dylib
	codesign -f -s - $(TARGET_TEST_APP_ROOT)/memedit.dylib

insert_dylib:
	clang -o tools/insert_dylib tools/insert_dylib.c

clean:
	rm -rf $(OBJDIR) memedit.dylib tools/insert_dylib
