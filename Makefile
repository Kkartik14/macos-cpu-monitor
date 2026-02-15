
BUILD_DIR = .build/release
APP_NAME = CPUMonitor
BUNDLE_NAME = $(APP_NAME).app
EXECUTABLE = $(BUILD_DIR)/$(APP_NAME)

all: build bundle

build:
	swift build -c release

bundle:
	mkdir -p $(BUNDLE_NAME)/Contents/MacOS
	mkdir -p $(BUNDLE_NAME)/Contents/Resources
	cp $(EXECUTABLE) $(BUNDLE_NAME)/Contents/MacOS/
	# Create a simple Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $(APP_NAME)" $(BUNDLE_NAME)/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.kartik.$(APP_NAME)" $(BUNDLE_NAME)/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleName string $(APP_NAME)" $(BUNDLE_NAME)/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1.0" $(BUNDLE_NAME)/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" $(BUNDLE_NAME)/Contents/Info.plist 

run: all
	open $(BUNDLE_NAME)

clean:
	rm -rf .build $(BUNDLE_NAME)
