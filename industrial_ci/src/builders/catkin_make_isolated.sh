#!/bin/bash

# Copyright (c) 2019, Mathias Lüdtke
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

function _append_job_opts() {
    local -n _append_job_opts_res=$1
    local jobs
    ici_parse_jobs jobs "$2" "$3"
    if [ "$jobs" -gt 0 ]; then
        _append_job_opts_res+=("-j$jobs" "-l$jobs")
    fi
}

function _run_catkin_make_isolated () {
    local target=$1; shift
    local extend=$1; shift
    local ws=$1; shift
    ici_cmd ici_exec_in_workspace "$extend" "$ws" catkin_make_isolated --build-space "$ws/build" --devel-space "$ws/devel" --install-space "$ws/install" --make-args "$target" "$@"
}
function _run_catkin_make_isolated_in_wrapper () {
    local build_wrapper=$1; shift
    local build_wrapper_args=$1; shift
    local target=$1; shift
    local extend=$1; shift
    local ws=$1; shift
    read -ra build_wrapper_args_arr <<< "$build_wrapper_args"
    ici_cmd ici_exec_in_workspace "$extend" "$ws" "$build_wrapper" "${build_wrapper_args_arr[@]}" catkin_make_isolated --build-space "$ws/build" --devel-space "$ws/devel" --install-space "$ws/install" --make-args "$target" "$@"
}

function builder_setup {
    ici_install_pkgs_for_command catkin_make_isolated "ros-${ROS_DISTRO}-catkin"
}

function builder_run_build {
    local extend=$1; shift
    local ws=$1; shift
    local opts=()
    _append_job_opts opts PARALLEL_BUILDS 0
    _run_catkin_make_isolated install "$extend" "$ws" "${opts[@]}" "$@"
}

function builder_run_build_in_wrapper {
    local build_wrapper=$1; shift
    local build_wrapper_args=$1; shift
    local extend=$1; shift
    local ws=$1; shift
    local opts=()
    _append_job_opts opts PARALLEL_BUILDS 0
    _run_catkin_make_isolated_in_wrapper "$build_wrapper" "${build_wrapper_args}" install "$extend" "$ws" "${opts[@]}" "$@"
}

function builder_run_tests {
    local extend=$1; shift
    local ws=$1; shift
    local opts=()
    _append_job_opts opts PARALLEL_TESTS 1
    _run_catkin_make_isolated run_tests "$extend" "$ws" "${opts[@]}"
}

function builder_test_results {
    local extend=$1; shift
    local ws=$1; shift
    ici_cmd ici_exec_in_workspace "$extend" "$ws" catkin_test_results --verbose
}
