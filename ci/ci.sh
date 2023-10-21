#!/bin/sh

set -eu

# Run CI-based tests for piet-wgpu

rx() {
  cmd="$1"
  shift

  (
    set -x
    "$cmd" "$@"
  )
}

piet_wgpu_check_target() {
  target="$1"
  command="$2"

  echo ">> Check for $target using $command"
  rustup target add "$target"
  rx cargo "$command" --target "$target" --no-default-features
  rx cargo "$command" --target "$target"
  cargo clean
}

piet_wgpu_test_version() {
  version="$1"
  extended_tests="$2"

  rustup toolchain add "$version" --profile minimal
  rustup default "$version"

  echo ">> Testing various feature sets..."
  rx cargo test
  rx cargo build --all --all-features --all-targets
  rx cargo build --no-default-features
  cargo clean

  if ! $extended_tests; then
    return
  fi
  
  RUSTFLAGS="--cfg=web_sys_unstable_apis" piet_wgpu_check_target wasm32-unknown-unknown build
  piet_wgpu_check_target x86_64-pc-windows-gnu build
  piet_wgpu_check_target x86_64-apple-darwin check
}

piet_wgpu_tidy() {
  rustup toolchain add stable --profile minimal
  rustup default stable

  rx cargo fmt --all --check
  rx cargo clippy --all-features --all-targets
}

. "$HOME/.cargo/env"

piet_wgpu_tidy
piet_wgpu_test_version stable true
piet_wgpu_test_version beta true
piet_wgpu_test_version nightly true
piet_wgpu_test_version 1.65.0 false

