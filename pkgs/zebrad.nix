# Zcash Foundation full node, built from source
{ lib, rustPlatform, fetchFromGitHub, protobuf, targetCpu ? null }:

rustPlatform.buildRustPackage rec {
  pname = "zebrad";
  version = "6.4.2";

  # Fork branch elicb/v6.4.2-reserved-listener-check-admission: v6.4.2 + reserved P2P listener +
  # journald-native logs + `checkadmission` RPC (zaino's admission check) + protoc ≥ 34 build fix
  src = fetchFromGitHub {
    owner = "elicbarbieri";
    repo = "zebra";
    rev = "b1cf6f8635573b316201043b1b276dda84f50f1c";
    hash = "sha256-rkzKeCVGVh1H0zwhNp5oHKbP8q4jwd788d6A7U/4fmQ=";
  };

  cargoHash = "sha256-S4/nSnv28L/7QH9gWHJLfUUZSQ+uORhx1w764uArQB0=";

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
