APP_NAME = Tachyon
APP_BUNDLE = $(APP_NAME).app
DMG_NAME = $(APP_NAME).dmg
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/apple/Products/Release
RELEASE_BIN = $(RELEASE_DIR)/$(APP_NAME)

.PHONY: all build bundle dmg install clean

all: install

build:
	@echo "🔨 Building $(APP_NAME)..."
	swift build -c release --disable-sandbox --arch arm64 --arch x86_64

bundle: build
	@echo "📦 Bundling $(APP_NAME).app..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@# Generate AppIcon.icns from icon.png
	@echo "🎨 Generating app icon..."
	@mkdir -p Resources/AppIcon.iconset
	@sips -z 16 16     Resources/icon.png --out Resources/AppIcon.iconset/icon_16x16.png > /dev/null
	@sips -z 32 32     Resources/icon.png --out Resources/AppIcon.iconset/icon_16x16@2x.png > /dev/null
	@sips -z 32 32     Resources/icon.png --out Resources/AppIcon.iconset/icon_32x32.png > /dev/null
	@sips -z 64 64     Resources/icon.png --out Resources/AppIcon.iconset/icon_32x32@2x.png > /dev/null
	@sips -z 128 128   Resources/icon.png --out Resources/AppIcon.iconset/icon_128x128.png > /dev/null
	@sips -z 256 256   Resources/icon.png --out Resources/AppIcon.iconset/icon_128x128@2x.png > /dev/null
	@sips -z 256 256   Resources/icon.png --out Resources/AppIcon.iconset/icon_256x256.png > /dev/null
	@sips -z 512 512   Resources/icon.png --out Resources/AppIcon.iconset/icon_256x256@2x.png > /dev/null
	@sips -z 512 512   Resources/icon.png --out Resources/AppIcon.iconset/icon_512x512.png > /dev/null
	@sips -z 1024 1024 Resources/icon.png --out Resources/AppIcon.iconset/icon_512x512@2x.png > /dev/null
	@iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
	@rm -rf Resources/AppIcon.iconset
	@cp $(RELEASE_BIN) $(APP_BUNDLE)/Contents/MacOS/
	@cp -R Resources/* $(APP_BUNDLE)/Contents/Resources/
	@# Copy SPM resource bundles if they exist
	@cp -R $(RELEASE_DIR)/*.bundle $(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true
	@cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@rm -f $(APP_BUNDLE)/Contents/Resources/Info.plist
	@# Sign with development certificate for persistent identity
	@# This allows macOS to remember accessibility permissions across rebuilds
	@# Falls back to ad-hoc signing if development certificate is not available
	@codesign --force --deep --sign "Apple Development" $(APP_BUNDLE) || codesign --force --deep --sign "-" $(APP_BUNDLE)
	@echo "✅ App bundle created at $(APP_BUNDLE)"

dmg: bundle
	@echo "💿 Creating $(DMG_NAME)..."
	@rm -f $(DMG_NAME)
	@hdiutil create -volname $(APP_NAME) -srcfolder $(APP_BUNDLE) -ov -format UDZO $(DMG_NAME)
	@echo "✅ DMG created at $(DMG_NAME)"

install: dmg
	@echo "🚀 Installing to /Applications..."
	@# Kill any running instance of Tachyon
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.5
	@# Reset accessibility permissions to avoid stale entries when signature changes
	@# This requires the bundle identifier from Info.plist
	@tccutil reset Accessibility com.tachyon.app 2>/dev/null || true
	@rm -rf /Applications/$(APP_BUNDLE)
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "✅ Installed $(APP_NAME) to /Applications"
	@echo ""
	@# Check if we used ad-hoc signing (which means permissions need to be re-granted)
	@if codesign -dv /Applications/$(APP_BUNDLE) 2>&1 | grep -q "adhoc"; then \
		echo "⚠️  Ad-hoc signed (no developer certificate found)"; \
		echo "   You will need to grant Accessibility permissions on first run."; \
		echo "   Go to: System Settings → Privacy & Security → Accessibility"; \
	else \
		echo "✅ Signed with developer certificate - permissions should persist"; \
	fi
	@echo ""
	@echo "🚀 Launching $(APP_NAME)..."
	@open /Applications/$(APP_BUNDLE)

clean:
	@echo "🧹 Cleaning..."
	@rm -rf $(BUILD_DIR) $(APP_BUNDLE) $(DMG_NAME)
