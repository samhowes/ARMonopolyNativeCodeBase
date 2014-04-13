#!/bin/sh

#  Script.sh
#  ARMonopolyNativeCodeBase
#
#  Created by Samuel Howes on 2/1/14.
#  Copyright (c) 2014 Samuel Howes. All rights reserved.
STORYBOARD="Main.storyboard ARMSectionHeaderView.xib"

CLASSES="ARM*.m ARM*.h"

IMAGES="LOGO.png tableview_checkmark.png"
AVATAR_DIR="Avatars"
IMAGEASSETS="Images.xcassets"

COPY_FILES="$STORYBOARD $CLASSES $IMAGES"
PRODUCT_DIR="../../ARMonopolyProduct"
LIBRARIES_DIR="../../ARMonopolyProduct/Libraries"

SPLASH_SCREEN="integration/SplashScreen.mm"

PROJECT_FILENAME="project.pbxproj"
UNITY_PROJECT_FILE="$LIBRARIES_DIR/../Unity-iPhone.xcodeproj/$PROJECT_FILENAME"
UNITY_COPY_TO="integration/$PROJECT_FILENAME"


if [ $1 ]; then
    echo "Copying Unity Project file to integration/ directory..."
    cp $UNITY_PROJECT_FILE $UNITY_COPY_TO

else
    echo "Copying classes into Unity Project folder at '$LIBRARIES_DIR'..."
    ### Copy all the files over
    for file in $COPY_FILES
    do
        echo "Copying '$file'..."
        cp $file "$LIBRARIES_DIR/"
    done

    echo "Copying project file to '$UNITY_PROJECT_FILE'..."

    mv $UNITY_PROJECT_FILE "$UNITY_PROJECT_FILE.replaced"
    cp $UNITY_COPY_TO $UNITY_PROJECT_FILE

    echo "Copying Custom Splash screen code..."
    cp $SPLASH_SCREEN "$PRODUCT_DIR/Classes/UI/"

    echo "Copying Images.xcassets over..."
    cp -a $IMAGEASSETS "$PRODUCT_DIR/Unity-iPhone/"
    cp -a $AVATAR_DIR "$LIBRARIES_DIR/$AVATAR_DIR"
fi

echo "Done!"
### Plugin installed!
