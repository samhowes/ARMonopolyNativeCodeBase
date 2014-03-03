#!/bin/sh

#  Script.sh
#  ARMonopolyNativeCodeBase
#
#  Created by Samuel Howes on 2/1/14.
#  Copyright (c) 2014 Samuel Howes. All rights reserved.
STORYBOARD="Main.storyboard"
PLUGIN_FILES="ARMPlayViewController.h ARMPlayViewController.m \
ARMAppController.h ARMAppController.m \
Base.lproj/Main.storyboard \
ARMEditProfileViewController.h ARMEditProfileViewController.m \
LeDiscovery.m LeDiscovery.h \
ARMBluetoothViewController.h ARMBluetoothViewController.m
ARMSettingsViewController.h ARMSettingsViewController.m \
ARMPlayerInfo.m ARMPlayerInfo.h"

COMPILE_DIR="../../ARMonopolyNative/Libraries/"

### Copy all the files over
for file in $PLUGIN_FILES
do
	cp $file $COMPILE_DIR
done


### Modify the storyboard for the new variables

# Replace the unitySubView with armUnitySubview in the outlet.
sed 's/property="unitySubView"/property="armUnitySubView"/g' $COMPILE_DIR$STORYBOARD > temp.xml
cp temp.xml $COMPILE_DIR$STORYBOARD
rm temp.xml

## Regex to add [super layoutSubviews];
#-\s*\(void\)layoutSubviews\s*\{([^\}].*\s)*

### Plugin installed!
