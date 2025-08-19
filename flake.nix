{
  description = "Cardano Transaction Generator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        jdk = pkgs.openjdk21;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Java/Scala toolchain
            jdk
            scala-cli
            graalvm-ce
            
            # Build tools
            git
            gnumake
            
            # Native compilation tools
            clang
            llvm
            
            # Shell utilities
            bashInteractive
          ];

          shellHook = ''
            echo "Cardano Transaction Generator Development Environment"
            echo "Scala CLI version: $(scala-cli version --cli-version)"
            echo "Java version: $(java -version 2>&1 | head -n 1)"
            echo "GraalVM version: $(native-image --version 2>&1 | head -n 1)"
            echo ""
            echo "Available make commands:"
            echo "  make build         - Compile the Scala project"
            echo "  make jar           - Create a fat JAR"
            echo "  make native        - Create GraalVM native image"
            echo "  make run           - Run the application"
            echo "  make test          - Run tests"
            echo "  make clean         - Clean build artifacts"
            echo "  make dist          - Create distribution package"
            echo "  make install-graalvm - Install GraalVM (macOS)"
            echo "  make help          - Show help message"
          '';

          # Set JAVA_HOME for scala-cli
          JAVA_HOME = "${jdk}";
        };
      });

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
    allow-import-from-derivation = true;
  };
}