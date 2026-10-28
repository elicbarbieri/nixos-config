# Zcash Foundation full node, built from source
{ lib, rustPlatform, fetchFromGitHub, protobuf, targetCpu ? null }:

rustPlatform.buildRustPackage rec {
  pname = "zebrad";
  version = "7.0.0-rc.0";

  # Fork branch zebra-deploy-target: v7.0.0-rc.0 + reserved P2P listener +
  # journald-native logs + `checkadmission` RPC (zaino's admission check) + protoc ≥ 34 build fix
  # + `[rpc] max_connections` (jsonrpsee's in-flight cap, upstream fixed at 100)
  src = fetchFromGitHub {
    owner = "elicbarbieri";
    repo = "zebra";
    rev = "2c8baf331a65ac25f1e58e9ce9ce832ee64de2e3";
    hash = "sha256-f1+hW2fyFv53aWi1Ti7hGqKIou4L6wS64KrxG59eA/U=";
  };

  cargoHash = "sha256-UMGQdlKv1mKNpHpCk2lxiqqV9s29DkUN1VGKv72hGWo=";

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
