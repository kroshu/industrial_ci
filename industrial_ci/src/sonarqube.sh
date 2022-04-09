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
	ici_install_pkgs_for_command ca-certificates ca-certificates
    wget -P ~/sonar/downloads https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip
    wget -P ~/sonar/downloads https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.4.0.2170.zip

    ici_install_pkgs_for_command unzip unzip
    unzip ~/sonar/downloads/build-wrapper-linux-x86.zip -d ~/sonar/tools
    unzip ~/sonar/downloads/sonar-scanner-cli-4.4.0.2170.zip -d ~/sonar/tools

    chmod +x ~/sonar/tools/build-wrapper-linux-x86/build-wrapper-linux-x86-64
    #chown root:root ~/sonar/build-wrapper-linux-x86/build-wrapper-linux-x86-64

    ln -s ~/sonar/tools/build-wrapper-linux-x86/build-wrapper-linux-x86-64 /usr/local/bin/sonar-build-wrapper
    ln -s ~/sonar/tools/sonar-scanner-4.4.0.2170/bin/sonar-scanner /usr/local/bin/sonar-scanner

    wget -P /usr/lib/cmake/CodeCoverage "https://raw.githubusercontent.com/kroshu/kroshu-tools/master/cmake/CodeCoverage.cmake"

    ici_asroot apt-get install -y default-jre

    export BUILD_WRAPPER="sonar-build-wrapper"
    export BUILD_WRAPPER_ARGS="--out-dir /root/sonar/bw_output"
    export SONARQUBE_PACKAGES_FILE="/root/sonar/packages"
    # export TEST_COVERAGE_PACKAGES_FILE="/root/sonar/coverage_pacakges"
    export TARGET_CMAKE_ARGS="${TARGET_CMAKE_ARGS} -DSONARQUBE_PACKAGES_FILE=${SONARQUBE_PACKAGES_FILE} --no-warn-unused-cli"
    if [ -n "$TEST_COVERAGE" ]; then
    	export TARGET_CMAKE_ARGS="${TARGET_CMAKE_ARGS} -DTEST_COVERAGE=on "
    fi

	touch ${SONARQUBE_PACKAGES_FILE}
	# touch ${TEST_COVERAGE_PACKAGES_FILE}

}

#function sonarqube_modify_builders {
#    echo "Builders modified"
#	colcon() {
#		echo "Using modified colcon"
#		sonar-build-wrapper --out-dir /root/sonar/bw_output colcon "$@"
#	}
#}

function sonarqube_generate_coverage_report {
	local -a args cmake_args
	ici_parse_env_array cmake_args CMAKE_ARGS

	args=(--cmake-args " -DTEST_COVERAGE=ON")
	if [ ${#cmake_args[@]} -gt 0 ]; then
        args+=("${cmake_args[@]}")
    fi
    args+=(--cmake-target coverage --cmake-target-skip-unavailable --cmake-clean-cache)

	builder_run_build "$@" "${args[@]}"
}

function sonarqube_analyze {
	local ws=$1; shift
	local -a branch_args
	local cov_report_path="/root/sonar/coverage_reports"
	mkdir ${cov_report_path}

	if [ "${EVENT_NAME}" == "push" ]; then
		branch_args=("-Dsonar.branch.name=${BRANCH}")
	else
		branch_args=("-Dsonar.pullrequest.key=${PR_NUMBER}"
					 "-Dsonar.pullrequest.branch=\"${PR_BRANCH}\""
					 "-Dsonar.pullrequest.base=\"${PR_NUMBER}\"")
	fi

	while read -r package
	do
		if [ -d "${ws}/build/${package}/test_coverage" ]; then
			cp -r "${ws}/build/${package}/test_coverage/" "${cov_report_path}/${package}"
		fi
	done < "${SONARQUBE_PACKAGES_FILE}"

	sonar-scanner -Dsonar.projectBaseDir="${ws}/src/${TARGET_REPO_NAME}" \
    			  -Dsonar.working.directory="/root/sonar/working_directory" \
    			  -Dsonar.cfamily.build-wrapper-output="/root/sonar/bw_output" \
    			  -Dsonar.cfamily.gcov.reportsPath="${cov_report_path}" \
    			  -Dsonar.cfamily.cache.enabled=false \
    			  "${branch_args[@]}"

}
