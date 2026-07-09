#!/bin/bash
set -e

echo "Starting AutoDockDrive in the background..."
./build/AutoDockDrive.app/Contents/MacOS/AutoDockDrive &
APP_PID=$!

function cleanup {
    echo "Cleaning up..."
    kill $APP_PID 2>/dev/null || true
    hdiutil detach "/Volumes/TestExternalDriveTest" 2>/dev/null || true
    rm -f ./TestExternalDriveTest.dmg
    hdiutil detach "/Volumes/MyUniqueTestDriveXYZ" 2>/dev/null || true
    rm -f ./MyUniqueTestDriveXYZ.dmg
}
trap cleanup EXIT

sleep 2

echo "Creating dummy DMG to act as an external drive..."
hdiutil create -size 10m -fs HFS+ -volname "MyUniqueTestDriveXYZ" ./MyUniqueTestDriveXYZ.dmg > /dev/null

echo "Mounting MyUniqueTestDriveXYZ..."
hdiutil attach ./MyUniqueTestDriveXYZ.dmg > /dev/null
sleep 2

echo "Checking if MyUniqueTestDriveXYZ is in com.apple.dock.plist..."
defaults read com.apple.dock persistent-others | grep "MyUniqueTestDriveXYZ" > /dev/null

if [ $? -eq 0 ]; then
    echo "FAILURE: MyUniqueTestDriveXYZ was added to the Dock! (DMG filtering failed)"
    exit 1
else
    echo "SUCCESS: MyUniqueTestDriveXYZ was properly ignored by DMG filtering."
fi

echo "Unmounting MyUniqueTestDriveXYZ..."
hdiutil detach "/Volumes/MyUniqueTestDriveXYZ" > /dev/null
sleep 2

echo "Cleaning up..."
kill $APP_PID
rm -f ./MyUniqueTestDriveXYZ.dmg

echo "Test complete!"
