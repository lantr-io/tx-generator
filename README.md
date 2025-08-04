# Scalus tx-generator for Midgard

A CLI application that generates and submits Cardano transactions to Midgard node for testing
purposes.

## Building

### Prerequisites

Nix or

- scala-cli
- make
- GraalVM (for native compilation)

### Build Commands

```bash
# use Nix to set up the development environment
nix develop

# Compile the project
make build

# Create a JAR file
make jar

# Create a native binary with GraalVM
make native

# Clean build artifacts
make clean

# Create a distribution package
make dist
```

### Install GraalVM (macOS) if not using Nix

```bash
make install-graalvm
```

After installation, set your environment variables:

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-ce-java17-*/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
```

## Usage

```bash
# Show help
./tx-generator --help

# Generate unlimited transactions to default URL (http://127.0.0.1:3000)
./tx-generator

# Generate 1000 transactions with custom URL
./tx-generator --url http://localhost:3000 --count 1000

# Generate transactions with 100ms delay between each
./tx-generator --delay 100

# Combine options
./tx-generator --url http://localhost:8080 --count 5000 --delay 50
```

## Options

- `--url` - Target URL for transaction submission (default: http://127.0.0.1:3000)
- `--count` - Number of transactions to generate (unlimited if not specified)
- `--delay` - Delay in milliseconds between transactions (default: 0)
