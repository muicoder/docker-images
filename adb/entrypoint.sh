#!/bin/bash

if [ -f ~/.android/${ADB_KEY_NAME:-adbkey} ]; then
	ls -A ~/.android
else
	if [ -f ~/.android/${ADB_KEY_NAME:-adbkey}.pub ]; then
		rm -rv ~/.android/${ADB_KEY_NAME:-adbkey}.pub
	fi
	adb keygen ~/.android/${ADB_KEY_NAME:-adbkey}
fi

exec "$@"
