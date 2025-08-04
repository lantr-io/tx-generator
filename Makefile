# Makefile for tx-generator with GraalVM native compilation

.PHONY: all build native clean install-graalvm

# Default target
all: native

# Build the Scala project
build:
	scala-cli compile .

# Create a fat JAR
jar:
	scala-cli --power package . -o tx-generator.jar --assembly

# Create GraalVM native image
native: jar
	native-image \
		--no-fallback \
		--enable-http \
		--enable-https \
		-H:+UnlockExperimentalVMOptions \
		-H:-CheckToolchain \
		-H:+ReportExceptionStackTraces \
		-H:+AddAllCharsets \
		--initialize-at-run-time=org.scalacheck.rng.Seed \
		--initialize-at-run-time=scala.util.Random \
		--initialize-at-run-time=java.util.Random \
		-H:ConfigurationFileDirectories=graalvm-config \
		-jar tx-generator.jar \
		-o tx-generator

# Run the application
run:
	scala-cli run src/ -- --help

# Test the application
test:
	scala-cli test src/

# Clean build artifacts
clean:
	rm -rf .scala-build/
	rm -f tx-generator.jar
	rm -f tx-generator

# Install GraalVM (macOS with brew)
install-graalvm:
	@echo "Installing GraalVM..."
	brew install --cask graalvm-ce-java17
	@echo "Don't forget to set JAVA_HOME and add GraalVM to your PATH:"
	@echo "export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-ce-java17-*/Contents/Home"
	@echo "export PATH=\$$JAVA_HOME/bin:\$$PATH"

# Create a simple distribution
dist: clean native
	mkdir -p dist
	cp tx-generator dist/
	cp README.md dist/ 2>/dev/null || echo "# tx-generator\n\nGenerate and submit Cardano transactions\n\n## Usage\n\n./tx-generator --help" > dist/README.md
	tar -czf tx-generator-dist.tar.gz dist/
	rm -rf dist/

# Help target
help:
	@echo "Available targets:"
	@echo "  build          - Compile the Scala project"
	@echo "  jar            - Create a fat JAR"
	@echo "  native         - Create GraalVM native image"
	@echo "  run            - Run the application"
	@echo "  test           - Run tests"
	@echo "  clean          - Clean build artifacts"
	@echo "  dist           - Create distribution package"
	@echo "  install-graalvm - Install GraalVM (macOS)"
	@echo "  help           - Show this help message"