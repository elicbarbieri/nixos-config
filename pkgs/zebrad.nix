# Zcash Foundation full node, built from source
{ lib, rustPlatform, fetchFromGitHub, protobuf, targetCpu ? null }:

rustPlatform.buildRustPackage rec {
  pname = "zebrad";
  version = "6.4.2";

  src = fetchFromGitHub {
    owner = "ZcashFoundation";
    repo = "zebra";
    tag = "v${version}";
    hash = "sha256-KtvGrXHLRhJnjnaxQvIoS4evB3EOKauChcbnYPACdAM=";
  };

  cargoHash = "sha256-S4/nSnv28L/7QH9gWHJLfUUZSQ+uORhx1w764uArQB0=";

  # rebase onto new tags (src touched: zebrad/src/components/tracing{.rs,/component.rs,/journal.rs})
  patches = [ ./zebrad-journal-stream.patch ];

  cargoBuildFlags = [ "--package" "zebrad" "--bin" "zebrad" ];

  # librocksdb-sys + zcash_script: bundled C++ → bindgen; zebra-rpc: tonic → protoc
  nativeBuildInputs = [ rustPlatform.bindgenHook protobuf ];

  env = {
    PROTOC = lib.getExe protobuf;
    # upstream release = thin LTO
    CARGO_PROFILE_RELEASE_LTO = "fat";
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
  } // lib.optionalAttrs (targetCpu != null) {
    # target-only (cargoBuildHook passes --target → build scripts untouched)
    RUSTFLAGS = "-C target-cpu=${targetCpu}";
    # bundled rocksdb / zcash_script C++ (cc-rs ignores rustc target-cpu)
    NIX_CFLAGS_COMPILE = "-march=${targetCpu}";
  };

  # upstream suite needs network + synced state
  doCheck = false;

  meta = {
    description = "Zcash full node (Zcash Foundation)";
    homepage = "https://github.com/ZcashFoundation/zebra";
    license = with lib.licenses; [ asl20 mit ];
    mainProgram = "zebrad";
    platforms = lib.platforms.linux;
  };
}
