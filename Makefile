# Makefile for Trend Vision One File Security Docker Container

.PHONY: help build test run clean scan scanfiles nfs

# Default target
help:
	@echo "Trend Vision One File Security Docker Container"
	@echo "=============================================="
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Build the Docker container"
	@echo "  test      - Run tests to verify the container"
	@echo "  run       - Run the container with NFS support"
	@echo "  scan      - Scan a single file (usage: make scan FILE=path/to/file)"
	@echo "  scanfiles - Scan multiple files (usage: make scanfiles PATH=/path/to/files)"
	@echo "  clean     - Clean up containers and images"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  ENDPOINT  - File Security service endpoint (default: localhost:50051)"
	@echo "  TLS       - Enable/disable TLS (default: true)"
	@echo "  APIKEY    - API key for authentication"
	@echo "  REGION    - Service region"
	@echo ""

# Build the container
build:
	@echo "Building Docker container..."
	docker build -t tmfs-scanner .
	@echo "✅ Container built successfully"

# Run tests
test:
	@echo "Running tests..."
	./test.sh

# Run container with NFS support
run:
	@echo "Starting container with NFS support..."
	docker run -d \
		--name tmfs-scanner \
		--privileged \
		-e ENDPOINT=$(ENDPOINT:-localhost:50051) \
		-e TLS=$(TLS:-true) \
		-e APIKEY=$(APIKEY) \
		-e REGION=$(REGION) \
		-v nfs-share:/mnt/nfs:shared \
		tmfs-scanner nfs
	@echo "✅ Container started. Use 'docker exec tmfs-scanner' to run commands"

# Scan a single file
scan:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: FILE parameter is required"; \
		echo "Usage: make scan FILE=path/to/file [ENDPOINT=host:port] [TLS=false]"; \
		exit 1; \
	fi
	@echo "Scanning file: $(FILE)"
	docker run --rm \
		-e ENDPOINT=$(ENDPOINT:-localhost:50051) \
		-e TLS=$(TLS:-true) \
		-e APIKEY=$(APIKEY) \
		-e REGION=$(REGION) \
		-e PML=$(PML:-false) \
		-e VERBOSE=$(VERBOSE:-false) \
		-v $(shell dirname $(FILE)):/app/files:ro \
		tmfs-scanner scan file:/app/files/$(shell basename $(FILE))

# Scan multiple files
scanfiles:
	@if [ -z "$(PATH)" ]; then \
		echo "❌ Error: PATH parameter is required"; \
		echo "Usage: make scanfiles PATH=/path/to/files [ENDPOINT=host:port] [TLS=false]"; \
		exit 1; \
	fi
	@echo "Scanning files in: $(PATH)"
	docker run --rm \
		-e ENDPOINT=$(ENDPOINT:-localhost:50051) \
		-e TLS=$(TLS:-true) \
		-e APIKEY=$(APIKEY) \
		-e REGION=$(REGION) \
		-e PML=$(PML:-false) \
		-e VERBOSE=$(VERBOSE:-false) \
		-v $(PATH):/app/files:ro \
		tmfs-scanner scanfiles -path=/app/files

# Clean up containers and images
clean:
	@echo "Cleaning up..."
	@docker stop tmfs-scanner 2>/dev/null || true
	@docker rm tmfs-scanner 2>/dev/null || true
	@docker rmi tmfs-scanner 2>/dev/null || true
	@docker volume rm nfs-share 2>/dev/null || true
	@echo "✅ Cleanup completed"

# Example usage
example:
	@echo "Creating example EICAR test file..."
	@mkdir -p files
	@echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$$H+H*' > files/eicar.com.txt
	@echo "✅ Example file created: files/eicar.com.txt"
	@echo ""
	@echo "To scan the example file:"
	@echo "  make scan FILE=files/eicar.com.txt ENDPOINT=your-endpoint:50051 TLS=false"

# NFS examples
nfs-test:
	@echo "Testing NFS connectivity to 192.168.200.10/mnt/nfs_share..."
	./test-nfs-connectivity.sh

nfs-scan:
	@echo "Starting interactive NFS scanning..."
	./example-nfs-scan.sh

nfs-quick:
	@echo "Quick NFS scan example:"
	@echo "1. Start container: docker run -d --name tmfs-nfs --privileged tmfs-scanner nfs"
	@echo "2. Mount NFS: docker exec tmfs-nfs mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/nfs"
	@echo "3. Scan files: docker exec tmfs-nfs /app/tmfs scan file:/mnt/nfs/filename.txt --tls=false --addr=my-release-visionone-filesecurity-scanner:50051"
	@echo "4. Cleanup: docker stop tmfs-nfs && docker rm tmfs-nfs" 