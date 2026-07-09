APP_NAME = AutoDockDrive
APP_BUNDLE = $(APP_NAME).app
MACOS_DIR = $(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources
SOURCES = $(wildcard Sources/*.swift)

all: $(MACOS_DIR)/$(APP_NAME)

$(MACOS_DIR)/$(APP_NAME): $(SOURCES)
	swiftc -O $(SOURCES) -o $(MACOS_DIR)/$(APP_NAME) -target x86_64-apple-macosx12.0 -target arm64-apple-macosx12.0

clean:
	rm -f $(MACOS_DIR)/$(APP_NAME)
