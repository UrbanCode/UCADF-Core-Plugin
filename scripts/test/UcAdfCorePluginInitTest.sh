#!/bin/sh

set -eu -o pipefail

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-ibm-1.8.0.5.20-1jpp.1.el7.x86_64/jre

export AGENT_HOME=/opt/ucdagent/ucdagent.ltsorch.ltucddev001a-test
export PATH=$PATH:$AGENT_HOME/opt/udclient

export AH_WEB_URL=
export DS_AUTH_TOKEN=

export CLASSPATH=.

#export GROOVY_HOME=$AGENT_HOME/opt/groovy-1.8.8

ucAdfPackageName=UCADF-Core-Package
ucAdfPackageVersion=4.4.258341

packageVersions=$ucAdfPackageName:$ucAdfPackageVersion

dlCommand='udclient --verbose -weburl "${AH_WEB_URL}" -authtoken "${DS_AUTH_TOKEN}" downloadVersionArtifacts -component "${ucAdfPackageName}" -version "${ucAdfPackageVersion}"'

#rm -rf ../UcAdfCorePluginDownloads

#cp UcAdfCorePluginActionsRunner "$AGENT_HOME/var/work/UcAdfCorePluginDownloads/$ucAdfPackageName/$ucAdfPackageVersion"
#cp UcAdfConfig.properties "$AGENT_HOME/var/work/UcAdfCorePluginDownloads/$ucAdfPackageName/$ucAdfPackageVersion"

echo "----- Running UcAdfCorePluginInit -----"
./UcAdfCorePluginInit "$packageVersions" "$dlCommand" input.props output.props
