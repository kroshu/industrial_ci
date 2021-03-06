# SonarQube integration

The kroshu fork of the industrial\_ci provides capabilities for analyzing your C/C++ code with SonarQube, including test coverage (using gcov). To simplify setting up your project for SonarQube analysis, check out [kroshu-tools](https://github.com/kroshu/kroshu-tools).

## How to use

### Configuring SonarQube

In order to be able to use SonarQube analysis, the project root directory has to contain the sonar-project.properties configuration file. More information: [SonarQube Documentation](https://docs.sonarqube.org/latest/analysis/analysis-parameters/). The following properties are set automatically, so you can skip them (setting them will have no effect):

- sonar.projectbaseDir
- sonar.working.directory
- sonar.cfamily.build-wrapper-output
- sonar.cfamily.gcov.reportsPath
- sonar.branch (if testing a push/merge)
- sonar.pullrequest.* (if testing a pull request) 

The following properties should be specified in the sonar-project.properties file:


- sonar.organization
- sonar.projectName
- sonar.ProjectKey
- sonar.host.url
- sonar.sources
- sonar.tests
- sonar.sourceEncoding

If your repository contains multiple ROS packages, it's recommended to specify a sonar module for each package and set the package specific properties in additional sonar-project.properties files in each package.

In your root sonar-project.properties:

- sonar.modules=module1,module2
- module?.sonar.projectBaseDir (if not a subdirectory of the root directory)

In your package's sonar-project.properties:

- sonar.sources
- sonar.tests

### Configuring Travis CI

In the .travis.yml configuration file there are two additional environment variables you can define:

- SONARQUBE: If set to true, runs SonarQube scan after the project has been built and tests have been run. Unset by default.
- TEST\_COVERAGE: If set to true, test coverage reports are also generated and analyzed by SonarQube. Unset by default. Note: to use the test coverage feature, your CMakeLists must contain the necessary additions. You can find a template [here](./CMakeLists_TestCoverageTemplate.txt), which you can append to the end of your CMakeLists. Note regarding the template: the name of the coverage target must be *coverage*, else industrial\_ci will exit with error. Support for multiple test coverage targets might be implemented in the future.

Furthermore, use the following commands in the install phase:

```
install:
  - git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/* # for correctly decorating pull requests
  - git fetch --unshallow --tags # for correct blame information
  - git clone --quiet --depth 1 https://github.com/kroshu/industrial_ci.git .industrial_ci # use the kroshu fork of industrial_ci
  - curl "https://raw.githubusercontent.com/davetcoleman/roscpp_code_format/master/.clang-format" -o .clang-format # clang format for ROS
```

To be able to publish analyzis results to your SonarQube server, you alse have to set the SONAR_TOKEN environment variable. See the SonarQube documentation for more details.

## How it works

SonarQube can only analyze C/C++ code if it was built using their [build-wrapper](https://docs.sonarqube.org/latest/analysis/languages/cfamily/). Because of this, build is performed using this wrapper. If test coverage report is requested, the additional cmake argument -DTEST_COVERAGE=ON is provided to the builder. After running the tests, a build is performed on the target *coverage*, which generates the coverage reports for the targets defined in your CMakeLists. Lastly, the SonarQube scanner is executed, and analysis report is sent to the server defined in your sonar-project.properties.