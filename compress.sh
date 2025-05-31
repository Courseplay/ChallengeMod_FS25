set -e

ZIP_NAME="FS22_ChallengeMode.zip"

# list all files that should be part of the zip archive
# seperate each file with a ' '. for each folder that you want to zip add a '/*' to the end.
# this means that you want to zip all files in that folder
FILES_TO_ZIP="modDesc.xml ChallengeModConfig.xml Icon_ChallengeMode.dds events/* gui/* gui/dialogs/* scripts/* translations/*"

zip "$ZIP_NAME" "$FILES_TO_ZIP"
mv "$ZIP_NAME" ..
