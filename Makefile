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
	@cp $(RELEASE_BIN) $(APP_BUNDLE)/Contents/MacOS/
	@cp -R Resources/* $(APP_BUNDLE)/Contents/Resources/
	@# Copy SPM resource bundles if they exist
	@cp -R $(RELEASE_DIR)/*.bundle $(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true
	@cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@rm -f $(APP_BUNDLE)/Contents/Resources/Info.plist
	@# Sign with development certificate for persistent identity
	@# This allows macOS to remember accessibility permissions across rebuilds
	@codesign --force --deep --sign "Apple Development" $(APP_BUNDLE)
	@echo "✅ App bundle created at $(APP_BUNDLE)"

dmg: bundle
	@echo "💿 Creating $(DMG_NAME)..."
	@rm -f $(DMG_NAME)
	@hdiutil create -volname $(APP_NAME) -srcfolder $(APP_BUNDLE) -ov -format UDZO $(DMG_NAME)
	@echo "✅ DMG created at $(DMG_NAME)"

install: dmg
	@echo "🚀 Installing to /Applications..."
	@rm -rf /Applications/$(APP_BUNDLE)
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "✅ Installed $(APP_NAME) to /Applications"
	@echo "   (You may need to grant permissions on first run)"

clean:
	@echo "🧹 Cleaning..."
	@rm -rf $(BUILD_DIR) $(APP_BUNDLE) $(DMG_NAME)
