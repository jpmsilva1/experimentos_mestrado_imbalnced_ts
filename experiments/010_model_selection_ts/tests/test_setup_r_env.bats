#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  SCRIPT_PATH="${BATS_TEST_DIRNAME}/../setup_r_env.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "setup_r_env.sh fails with usage error when project name is missing" {
  run bash "$SCRIPT_PATH"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "ERROR: Missing project name" ]]
}

@test "setup_r_env.sh accepts project name and parses empty package files gracefully" {
  touch "$TEST_DIR/conda_pkgs.txt"
  touch "$TEST_DIR/r_pkgs.txt"
  
  # Run in dry mode (checking initial print statements)
  run bash -c "bash '$SCRIPT_PATH' test_env '$TEST_DIR/conda_pkgs.txt' '$TEST_DIR/r_pkgs.txt' | head -n 6"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Project:    test_env" ]]
}
