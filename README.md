# UCADF-Core-Plugin
The UrbanCode Application Deployment Framework (UCADF) Core plugin is an UrbanCode Deploy automation plugin that runs UCADF actions provided by the UCADF Core Library functionality.

The is a lightweight wrapper with plugin properties that don't change so that its usage can remain predictable long-term for all of the UrbanCode Versions and UrbanCode instances in which it runs. This allows the plugin "interface" (the plugin properties) to remain stable while the implementation (the underlying plugin functionality) can change as needed to provide multi-version/multi-platform functionality.

### Related Projects
The [UCADF-Core-Library](https://github.com/UrbanCode/UCADF-Core-Library) and [UCADF-Store](https://github.com/UrbanCode/UCADF-Store) projects provide related information.

## How the UCADF Core Plugin Differs from a Typical Automation Plugin
A typical UrbanCode automation plugin version has specific steps and properties defined in the UI process designer. At runtime the plugin version will download itself to an agent as it is needed to perform a step on the agent. The plugin then contains all of the files it needs to implement the step. (Some plugins may rely on other software previously installed on the agent.) If the plugin implementation needs to change then a new version of the plugin must be installed which in turn updates any processes using the plugin.

The UCADF Core Plugin is also an automation plugin that has a single step and a few properties defined in the UI process designer. One of the properties is used to define all of the actions that will be run by that step. Like a typical plugin, at runtime the plugin version will download itself to an agent as it is needed to perform a step on the agent. At this point is where the UCADF Core Plugin differs from the typical UrbanCode plugin. The UCADF Core Plugin does not contain the implementation files but rather the scripts needed to download the implementation files. This architecture allows the plugin version to remain the same while having the flexibility to dynamically change the plugin's implementation based on which package versions are defined for the step. 

## UCADF Core Plugin Usage of UCADF Packages
The UCADF Core Plugin expects the implementation files to be provided by UCADF packages. A UCADF package is used to bundle a set of UCADF action functionality. Each UCADF package version contains all of the files that might be required to run the UCADF actions provided by that package.

s### Directory Structure of a UCADF Package Version Downloaded by the Plugin 
```
${AGENT_HOME}/var/work
   /UcAdfCorePluginDownloads
      /[PackageName]
         /[VersionName]
            /Actions
               *.yml (action files)
            /Applications
               /[ApplicationName]
                  (The application export files.)
            /Libraries
               (The library files.)           
            /NotificationTemplates
               (The notification template files.)
            /Tests
               (The tests files.)
            UcAdfConfig.properties
```
## Specifying Package Versions to use at Runtime
The UCADF Core Plugin also has the abiity to use multiple UCADF Packages withing a single step execution based on a package versions specification provided in the step. 
```
Format:
<packageName>:<packageVersion>[,...]

Example:
ABC-UCADF-Package:1.0.0,UCADF-Core-Package:1.0.0
```
The package versions specification should typically have any packages that extend the core listed first, so that it's possible to override certain core actions if desired.

A best practice is to set a UCD system property such as:
```
ABC-UCADF-Package-Versions=ABC-UCADF-Package:1.0.0,UCADF-Core-Package:1.0.0
```

***Combining Versions in Different Instances***
If is possible for different UCADFs to rely on different versions of other UCADFs and for those to vary across instances. This provides the ability to stabilize one UCADF on an instance with a given set of versions then still be able to use newer UCADF versions for other UCADFs.

| Instance | System Properties |
|:-------- |:----------- |
| ucadfdev | UCADF-Core-Package-Versions=UCADF-Core-Package:2.0.0 |
| | ABC-UCADF-Package-Versions=ABC-UCADF-Package:2.0.0,UCADF-Core-Package:1.0.0 |
| | FOO-UCADF-Package-Versions=FOO-UCADF-Package:1.0.0,UCADF-Core-Package:2.0.0 |
| ucadftest | UCADF-Core-Package-Versions=UCADF-Core-Package:1.0.0 |
| | ABC-UCADF-Package-Versions=ABC-UCADF-Package:1.0.0,UCADF-Core-Package:1.0.0 |

## The actionPackages Properties
The plugin provides the actionPackages properties that are useful in the plugin step. Acessing these property values done by using the format:
```
actionPackages/[PackageName]/[ProperyName]
```
Where PackageName is the name of the package and Property Name is:

| PropertyName | Description |
|:-------- |:----------- |
| name | The name of the package, e.g. ABC-UCADF-Package |
| directoryName | The package directory on the agent, e.g. /opt/ucdagent/var/work/UcAdfCorePluginDownloads/ABC-UCADF-Package/20190824160357 |
| actionsDirectoryName | The package actions directory on the agent, e.g. /opt/ucdagent/var/work/UcAdfCorePluginDownloads/ABC-UCADF-Package/20190824160357/Actions |
| version | The package version, e.g. 20190824160357 |


## Plugin Steps
The plugin currently has only one step.

### STEP: Run UCADF Actions
This step runs a set of UCADF actions.<br>

**Use UCADF Package Versions:**<br>
The UCADF packages versions specification. This example uses a system property.
```
${p:ABC-UCADF-Package-Versions}
```

**Actions Text:**<br>
The YAML text that describes the actions to be run.<p>
The plugin provides the location of a given package's action files in the UCADF property: "${u:actionsPackages/[PackageName]/actionsDirectoryName}", where actionPackages is the collection name, [PackageName] is a key in that collection, and actionsDirectoryName is always 'Actions'.

```
# Load ABC general properties to be used by the ABC action processing.
propertyFiles:
  - fileName: "${u:actionPackages/ABC-UCADF-Package/actionsDirectoryName}/AbcUcAdfActionProperties.yml"

actions:
  # Run the comment action.
  - action: UcAdfComment
    comment: "This is a test comment"
```

Pre-processing UrbanCode Deploy Properties 
```
// Get the team roles list by splitting (by end of line or comma) the groups string supplied from a multi-select list or a text area.
List teamRolesList = roleNames.split(/,|\r?\n/).collect{ /{ team: "$teamName", role: "$it" }/}
println "teamRolesList=$teamRolesList"

// Create a string that represents a team roles JSON array.
String teamRolesJson = "[" + teamRolesList.join(",") + "]"
println "teamRolesJson=$teamRolesJson"

// Set a property to the JSON string.
outProps.put("teamRolesJson", teamRolesJson)

```

**Download Command:**<br>
This is the download command to run once for each of the requested UCADF package versions for the plugin step. The following values are available for the download command to use as variables:
* ucAdfPackageName - The UCADF package name.
* ucAdfPackageVersion - The UCADF package version name.

The default download command will download the UCADF package version from the respective component version name in the UCD instance running the step:<br>
```
udclient --verbose -weburl "${AH_WEB_URL}" -authtoken "${DS_AUTH_TOKEN}" downloadVersionArtifacts -component "${ucAdfPackageName}" -version "${ucAdfPackageVersion}
```
 
## How the Plugin Processing Works
1. The plugin runs the ***UcAdfCorePluginInit*** script that parses the package versions value and downloads those package versions that haven't already been downloaded. As it processes each package version in order it looks for the first one that has a runner script, thus allowing a package to have its own custom ***UcAdfCorePluginActionsRunner*** script if needed. This script then runs the ***UcAdfCorePluginActionsRunner*** script.
2. The ***UcAdfCorePluginActionsRunner*** script that parses the package version spec and processes each package version directory collecting information from the respective configuration files. It then uses the information to construct a classpath in the order of the specified package versions.

## Platform Notes
This plugin currently only works on Linux agents.

## Building and Publishing the Plugin
Use the following commands to build the plugin.
~~~
# Define Maven repository.
export MVN_REPO_ID=MyRepoID
export MVN_REPO_NAME=MyRepoName
export MVN_REPO_URL=MyRepoURL

# Define the version of the plugin when it is installed in an UrbanCode instance.
export UCADF_PLUGIN_INSTALL_VERSION=50

# Define the version of the plugin as it will be deployed to Maven.
export UCADF_PLUGIN_VERSION=1.0.50

# Set the version number in the pom.xml file.
mvn versions:set -DnewVersion="$UCADF_PLUGIN_VERSION"

mvn -U clean package -DUCADF_PLUGIN_VERSION="$UCADF_PLUGIN_VERSION" -DUCADF_PLUGIN_INSTALL_VERSION="$UCADF_PLUGIN_INSTALL_VERSION"
~~~
After that build completes the use the following command to deploy the plugin zip file to Maven.
~~~
mvn deploy:deploy-file -DgeneratePom=false -DgroupId=org.urbancode.ucadf.core -DartifactId=UCADF-Core-Plugin -Dversion="$UCADF_PLUGIN_VERSION" -Dpackaging=zip -Dfile="releases/UCADF-Core-Plugin-v$UCADF_PLUGIN_VERSION.zip" -DrepositoryId="$MVN_REPO_ID" -Durl="$MVN_REPO_URL"
~~~

## Installing the Plugin
The plugin package file may be manually installed using the UrbanCode Deploy UI plugin installation functionality. The installed plugin name will be ***UCADF Core***.

## License
This project is licensed under the MIT License - see the [LICENSE](../LICENSE.md) file for details
