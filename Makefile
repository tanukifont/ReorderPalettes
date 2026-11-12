BUNDLE = ReorderPalettes.glyphsPlugin
CONTENTS = $(BUNDLE)/Contents
EXECUTABLE = $(CONTENTS)/MacOS/ReorderPalettes
SOURCES = $(addprefix ReorderPalettes/,ReorderPalettesPlugin.m ROPPalettePlugin.m ROPWindowController.m ROPTableColumn.m)
HEADERS = $(SOURCES:.m=.h)
VERSION = $(shell /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' ReorderPalettes/Info.plist)

.PHONY: all plugin archive
all: plugin

plugin: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES) $(HEADERS) ReorderPalettes/Info.plist $(CONTENTS)/Resources/ROPWindowController.nib LICENSE NOTICE
	mkdir -p $(CONTENTS)/MacOS
	cp ReorderPalettes/Info.plist $(CONTENTS)/Info.plist
	cp LICENSE NOTICE $(CONTENTS)/Resources/
	xcrun clang -arch arm64 -arch x86_64 -mmacosx-version-min=12.0 -fobjc-arc -Wall -Wextra -Wno-unused-parameter -Werror -framework Cocoa -bundle $(SOURCES) -o $@
	codesign --force --sign - $(BUNDLE)

archive: plugin
	mkdir -p build
	ditto -c -k --keepParent --norsrc $(BUNDLE) build/ReorderPalettes-$(VERSION).zip
