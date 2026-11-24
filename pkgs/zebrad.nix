# Zcash Foundation full node, built from source
{ lib, rustPlatform, fetchFromGitHub, protobuf, pkg-config, libgit2, targetCpu ? null }:

rustPlatform.buildRustPackage rec {
  pname = "zebrad";
  version = "7.0.0";

  # Fork branch zebra-deploy-target-v7: v7.0.0 (mainnet NU7 at 3,543,405) + reserved P2P listener +
  # journald-native logs + `checkadmission` RPC (zaino's admission check) + protoc ≥ 34 build fix
  # + `[rpc] max_connections` (jsonrpsee's in-flight cap, upstream fixed at 100)
  src = fetchFromGitHub {
    owner = "elicbarbieri";
    repo = "zebra";
    rev = "6a09714d6a31395e9ac236640bbea9fa462148af";
    hash = "sha256-0wfxhm4yvWeO63ighEHSOX1eephgjjezUx5jjsmZn+4=";
  };

  cargoHash = "sha256-kgdpFXUhhZRuTDxxdyw4peqvyejDUakt3nlmV7Z1fls=";

  cargoBuildFlags = [ "--package" "zebrad" "--bin" "zebrad" ];

  # librocksdb-sys + zcash_script: bundled C++ → bindgen; zebra-rpc: tonic → protoc
  # libgit2-sys (vergen): cargoSetupHook sets LIBGIT2_NO_VENDOR=1 → system libgit2 via pkg-config
  nativeBuildInputs = [ rustPlatform.bindgenHook protobuf pkg-config ];
  buildInputs = [ libgit2 ];

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
