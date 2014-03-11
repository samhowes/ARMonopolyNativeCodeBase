#!/bin/sh

#  Script.sh
#  ARMonopolyNativeCodeBase
#
#  Created by Samuel Howes on 2/1/14.
#  Copyright (c) 2014 Samuel Howes. All rights reserved.
STORYBOARD="Base.lproj/Main.storyboard"
SETTINGS_CONTROLLERS="\
ARMSettingsViewController.h     ARMSettingsViewController.m     \
ARMEditProfileViewController.h  ARMEditProfileViewController.m  \
ARMBluetoothViewController.h    ARMBluetoothViewController.m    \
ARMNetworkViewController.h      ARMNetworkViewController.m      \
"
BLUETOOTH="\
LeDiscovery.h                   LeDiscovery.m                   \
"
DATA_MODEL="\
ARMPlayerInfo.h                 ARMPlayerInfo.m                 \
"
DEPLOY_ONLY="\
ARMAppController.h              ARMAppController.m              \
"
CLASSES="\
ARMPlayViewController.h         ARMPlayViewController.m         \
$DATA_MODEL $SETTINGS_CONTROLLERS $BLUETOOTH $DEPLOY_ONLY"
LOGO="LOGO.png"


COPY_FILES="$STORYBOARD $CLASSES $LOGO"
COMPILE_DIR="../../ARMonopolyProduct/Libraries/"

### Copy all the files over
for file in $COPY_FILES
do
	cp $file $COMPILE_DIR
done

### Plugin installed!
