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
	
	ici_install_pkgs_for_command wget wget
    wget -P ~/sonar/downloads https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip
    wget -P ~/sonar/downloads https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.0.0.1744-linux.zip
    
    ici_install_pkgs_for_command unzip unzip
    unzip ~/sonar/downloads/build-wrapper-linux-x86.zip -d ~/sonar/tools
    unzip ~/sonar/downloads/sonar-scanner-cli-4.0.0.1744-linux.zip -d ~/sonar/tools
    
    chmod +x ~/sonar/tools/build-wrapper-linux-x86/build-wrapper-linux-x86-64
    #chown root:root ~/sonar/build-wrapper-linux-x86/build-wrapper-linux-x86-64
    
    ln -s ~/sonar/tools/build-wrapper-linux-x86/build-wrapper-linux-x86-64 /usr/local/bin/sonar-build-wrapper
    ln -s ~/sonar/tools/sonar-scanner-4.0.0.1744-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner
    
    wget -P /usr/lib/cmake/CodeCoverage "https://raw.githubusercontent.com/kroshu/kroshu-tools/master/cmake/CodeCoverage.cmake" 
    
    ici_asroot apt-get install -y default-jre
    
    export BUILD_WRAPPER="sonar-build-wrapper --out-dir /root/sonar/bw_output"
    export SONARQUBE_PACKAGES_FILE="/root/sonar/packages"
    # export TEST_COVERAGE_PACKAGES_FILE="/root/sonar/coverage_pacakges"
    export TARGET_CMAKE_ARGS="${TARGET_CMAKE_ARGS} -DSONARQUBE_PACKAGES_FILE=${SONARQUBE_PACKAGES_FILE} --no-warn-unused-cli"
    if [ -n "$TEST_COVERAGE" ]; then
    	export TARGET_CMAKE_ARGS="${TARGET_CMAKE_ARGS} -DTEST_COVERAGE=on "
    fi

	touch ${SONARQUBE_PACKAGES_FILE}
	touch ${TEST_COVERAGE_PACKAGES_FILE}
	
}

#function sonarqube_modify_builders {
#    echo "Builders modified"
#	colcon() {
#		echo "Using modified colcon"
#		sonar-build-wrapper --out-dir /root/sonar/bw_output colcon "$@"
#	}
#}

function sonarqube_generate_coverage_report {
	ici_parse_env_array cmake_args CMAKE_ARGS
	local -a args
	args=(--cmake-args " -DTEST_COVERAGE=ON")
	if [ ${#cmake_args[@]} -gt 0 ]; then
        args+=("${cmake_args[@]}")
    fi
    args+=(--cmake-target coverage --cmake-target-skip-unavailable --cmake-clean-cache)
	builder_run_build "$@" "${args[@]}"
}

function sonarqube_analyze {
	local name=$1; shift
	local -a opt_pr_args
	echo "${TRAVIS_PULL_REQUEST}"
	echo "${TRAVIS_PULL_REQUEST_BRANCH}"
	echo "${TRAVIS_BRANCH}"
	if [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
		opt_pr_args=(-Dsonar.pullrequest.key="${TRAVIS_PULL_REQUEST}"
					 -Dsonar.pullrequest.branch="${TRAVIS_PULL_REQUEST_BRANCH}"
					 -Dsonar.pullrequest.base="${TRAVIS_BRANCH}")
	fi
	
	#echo "$(cat /root/sonar/bw_output/build-wrapper-dump.json)"
	
	while IFS=';' read -r package_name package_source_dir
	do
		if [ -n $package_name ]; then
		    echo "Package:$package_name, source: $package_source_dir"
			sonar-scanner -Dsonar.projectBaseDir="${TARGET_REPO_PATH}" \
		    			  -Dsonar.working.directory="/root/sonar/working_directory" \
		    			  -Dsonar.cfamily.build-wrapper-output="/root/sonar/bw_output" \
		    			  -Dsonar.cfamily.gcov.reportsPath="${current_ws}/build/${package_name}/test_coverage" \
		    			  -Dsonar.cfamily.cache.enabled=false \
		    			  "${opt_pr_args[@]}"
		fi
	done < "${SONARQUBE_PACKAGES_FILE}"
}
