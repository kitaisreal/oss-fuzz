#!/bin/bash -eu
# Copyright 2020 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# Build and install atheris (using current CFLAGS, CXXFLAGS).
pip3 install --force-reinstall atheris

# Build and install project (using current CFLAGS, CXXFLAGS).
pip3 install .

# Bundle ASAN runtime lib in $OUT.
sanitizer_runtime="libclang_rt.asan-x86_64.so"
cp $(find $(llvm-config --libdir) -name $sanitizer_runtime) $OUT/

# Build fuzzers in $OUT.
for fuzzer in $(find $SRC -name '*_fuzzer.py'); do
  fuzzer_basename=$(basename -s .py $fuzzer)
  fuzzer_package=${fuzzer_basename}.pkg
  pyinstaller --distpath $OUT --onefile --name $fuzzer_package $fuzzer

  # Create execution wrapper.
  echo "#/bin/bash
  # LLVMFuzzerTestOneInput string for fuzzer detection.
  LD_PRELOAD=\$(dirname "\${BASH_SOURCE[0]}")/$sanitizer_runtime \$(dirname "\${BASH_SOURCE[0]}")/$fuzzer_package \$@" > $OUT/$fuzzer_basename
  chmod u+x $OUT/$fuzzer_basename
done