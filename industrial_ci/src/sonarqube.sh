#!/bin/bash

# Copyright (c) 2019, Zoltán Rési
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function sonarqube_setup {
	mkdir -p ~/sonar
    ici_import_url ~/sonar https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.0.0.1744-linux.zip
    ici_import_url ~/sonar https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip
    
    ici_asroot ln -s ~/sonar/build-wrapper-linux-x86/build-wrapper-linux-x86-64 /usr/local/bin/build-wrapper
    ici_asroot ln -s ~/sonar/sonar-scanner-4.0.0.1744-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner
    ls -l ~/sonar
    ls -l /usr/local/bin
    ici_asroot chmod root:root ~/sonar/build-wrapper-linux-x86/build-wrapper-linux-x86-64
    ls -l ~/sonar
    ls -l /usr/local/bin
}

function sonarqube_build_wrapper {
    build-wrapper --out-dir "~/sonar/bw_output" "$@"
}

function sonarqube_analyze {
    ici_run "sonarqube_analyze_${current_ws}" \
	    sonar-scanner -Dsonar.projectBaseDir="$current_ws/src/$TARGET_REPO_NAME" \
	    			  -Dsonar.working.directory="~/sonar/working_directory" \
	    			  -Dsonar.cfamily.build-wrapper-output="${current_ws}/sonar/bw_output" 
	    			  #-Dsonar.cfamily.gcov.reportsPath=/root/catkin_ws/build/beginner_tutorials/test_coverage
}
