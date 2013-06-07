#!/bin/bash

if [ "$#" -lt 4 ] ; then
	echo "Arguments missing! Usage: `basename $0` <plugin-home> <group-id> <plugin-name> <releases_dir>"
	exit 1
else
	PLUGIN_HOME="$1"
	GROUP_ID="$2"
	PLUGIN_NAME="$3"
	DEST="$4"
fi

function findInPluginDescription() {
	RES=$(cat *GrailsPlugin.groovy | grep "def $1 = " | cut -d"'" -f2)
	echo "$RES" | grep "def $1 = " &> /dev/null && RES=$(cat *GrailsPlugin.groovy | grep "def $1 = " | cut -d'"' -f2)
	echo "$RES"
}

function absolutePath() {
	echo "$(cd $(dirname $1) && pwd)/$(basename $1)"
}

SCRIPT_TMP="/tmp/`basename $0`.$$"
DEST_FROM_GROUP="$(echo $GROUP_ID | tr '.' '/' )"
TEMPLATE="$(absolutePath `dirname $0`/template.pom)"
DEST="$(absolutePath $DEST)"
PLUGIN_HOME="$(absolutePath $PLUGIN_HOME)"

echo "Compiling and building plugin..."
cd "$PLUGIN_HOME"
PLUGIN_VERSION=$(findInPluginDescription version)
DESCRIPTION=$(findInPluginDescription description)
JAR_FILENAME=grails-plugin-"$PLUGIN_NAME"-"$PLUGIN_VERSION".jar 
grails clean && grails compile && grails package-plugin --binary
if [ ! -f "target/$JAR_FILENAME" ] ; then
	echo "target/$JAR_FILENAME not found after building binary plugin, aborting..."
	exit 1
fi

mkdir "$SCRIPT_TMP"
cd "$SCRIPT_TMP"

echo "Generating pom from template..."
cat "$TEMPLATE" | sed "s/_GROUP_ID_/$GROUP_ID/" | \
	sed "s/_NAME_/$PLUGIN_NAME/" | \
	sed "s/_VERSION_/$PLUGIN_VERSION/" | \
	sed "s/_DESCRIPTION_/$DESCRIPTION/" > $PLUGIN_NAME.pom

echo "Installing version $GROUP_ID:$PLUGIN_NAME:$PLUGIN_VERSION with description '$DESCRIPTION'"

mvn install:install-file -Dmaven.repo.local="." -Dfile="$PLUGIN_HOME/target/$JAR_FILENAME" -DgroupId="$GROUP_ID" \
	-DartifactId="$PLUGIN_NAME" -Dversion="$PLUGIN_VERSION" -DpomFile="$PLUGIN_NAME.pom" -Dpackaging=jar -DcreateChecksum=true

echo "Moving $DEST_FROM_GROUP/$PLUGIN_NAME to $DEST"

mkdir -p $DEST/$DEST_FROM_GROUP
cp -R $DEST_FROM_GROUP/$PLUGIN_NAME $DEST/$DEST_FROM_GROUP
# rm -r "$SCRIPT_TMP" 
