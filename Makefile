.PHONY: app run test format

app:
	./Scripts/build-app.sh

run: app
	open "$(HOME)/Applications/Menu Bar Monitor.app"

test:
	swift test

format:
	xcrun swift-format format --in-place --recursive Sources Tests Package.swift
