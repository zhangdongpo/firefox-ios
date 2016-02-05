#!/bin/sh

if [ ! -d Client.xcodeproj ]; then
  echo "Please run this from the project root that contains Client.xcodeproj"
  exit 1
fi

if [ -d firefox-ios-l10n ]; then
  if [ -d firefox-ios-l10n/.git ]; then
    echo "updating existing firefox-ios-l10n Git repo"
    git pull --rebase
  else
    echo "Creating firefox-ios-l10n Git repo"
    git clone https://github.com/mozilla-l10n/firefoxios-l10n firefox-ios-l10n || exit 1
  fi
fi
echo "Creating firefox-ios-l10n Git repo"
svn export --force https://github.com/mozilla-l10n/firefoxios-l10n/trunk firefox-ios-l10n || exit 1

#
# TODO Add incomplete locales here that are NOT to be included.
# TODO Look at https://l10n.mozilla-community.org/~flod/webstatus/?product=firefox-ios to find out which locales are not at 100%
#

INCOMPLETE_LOCALES=(
    "ar"
    "az"
    "da"
    "kk"
    "lo"
    "ms"
    "my"
    "son"
    "th"
)

if [ "$1" == "--only-complete" ]; then
  for i in "${!INCOMPLETE_LOCALES[@]}"; do
    echo "Removing incomplete locale ${INCOMPLETE_LOCALES[$i]}"
    rm -rf "firefox-ios-l10n/${INCOMPLETE_LOCALES[$i]}"
  done
fi

# Cleanup files (remove unwanted sections, map sv-SE to sv)
scripts/update-xliff.py firefox-ios-l10n || exit 1

# Remove unwanted sections like Info.plist files and $(VARIABLES)
scripts/xliff-cleanup.py firefox-ios-l10n/*/*.xliff || exit 1

# Export xliff files to individual .strings files
rm -rf localized-strings || exit 1
mkdir localized-strings || exit 1
scripts/xliff-to-strings.py firefox-ios-l10n localized-strings|| exit 1

# Modify the Xcode project to reference the strings files we just created
scripts/strings-import.py Client.xcodeproj localized-strings || exit 1
