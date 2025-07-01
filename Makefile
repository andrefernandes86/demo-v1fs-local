# Makefile for Trend Vision One CLI File Security Scanner

# Default values
DOCKER_IMAGE = tmfs-scanner
DOCKER_COMPOSE_FILE = docker-compose.yml
ENV_FILE = .env

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

.PHONY: help build build-no-cache clean run scan scan-dir monitor nfs stop logs status test

help: ## Show this help message
	@echo "$(GREEN)🛡️ Trend Vision One CLI File Security Scanner$(NC)"
	@echo "============================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the CLI scanner container
	@echo "$(GREEN)🔨 Building CLI scanner container...$(NC)"
	docker build -t $(DOCKER_IMAGE) .

build-no-cache: ## Build the CLI scanner container without cache
	@echo "$(GREEN)🔨 Building CLI scanner container (no cache)...$(NC)"
	docker build --no-cache -t $(DOCKER_IMAGE) .

clean: ## Remove containers and images
	@echo "$(YELLOW)🧹 Cleaning up containers and images...$(NC)"
	docker-compose -f $(DOCKER_COMPOSE_FILE) down --rmi all
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

run: ## Start the monitoring service
	@echo "$(GREEN)🚀 Starting CLI scanner monitoring service...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Error: $(ENV_FILE) file not found. Please create it with your TM_API_KEY.$(NC)"; \
		exit 1; \
	fi
	docker-compose -f $(DOCKER_COMPOSE_FILE) up -d

scan: ## Scan a single file (usage: make scan FILE=/path/to/file)
	@echo "$(GREEN)🔍 Scanning file: $(FILE)$(NC)"
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)❌ Error: FILE parameter required. Usage: make scan FILE=/path/to/file$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f $(ENV_FILE) ] && [ -z "$(TM_ENDPOINT)" ] && [ -z "$(TM_API_KEY)" ]; then \
		echo "$(RED)❌ Error: Either $(ENV_FILE) file, TM_ENDPOINT (local), or TM_API_KEY (cloud) is required.$(NC)"; \
		echo "$(YELLOW)Examples:$(NC)"; \
		echo "$(YELLOW)  make scan FILE=/path/to/file TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false$(NC)"; \
		echo "$(YELLOW)  make scan FILE=/path/to/file --env-file .env$(NC)"; \
		exit 1; \
	fi
	docker run --rm \
		$(if $(TM_ENDPOINT),-e TM_ENDPOINT=$(TM_ENDPOINT),) \
		$(if $(TM_API_KEY),-e TM_API_KEY=$(TM_API_KEY),) \
		$(if $(TM_TLS),-e TM_TLS=$(TM_TLS),-e TM_TLS=false) \
		$(if $(TM_REGION),-e TM_REGION=$(TM_REGION),) \
		$(if $(ENV_FILE),--env-file $(ENV_FILE),) \
		-v $(FILE):/app/file:ro \
		$(DOCKER_IMAGE) scan /app/file

scan-dir: ## Scan a directory (usage: make scan-dir DIR=/path/to/directory)
	@echo "$(GREEN)🔍 Scanning directory: $(DIR)$(NC)"
	@if [ -z "$(DIR)" ]; then \
		echo "$(RED)❌ Error: DIR parameter required. Usage: make scan-dir DIR=/path/to/directory$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f $(ENV_FILE) ] && [ -z "$(TM_ENDPOINT)" ]; then \
		echo "$(RED)❌ Error: Either $(ENV_FILE) file or TM_ENDPOINT environment variable is required.$(NC)"; \
		exit 1; \
	fi
	docker run --rm \
		$(if $(TM_ENDPOINT),-e TM_ENDPOINT=$(TM_ENDPOINT),--env-file $(ENV_FILE)) \
		$(if $(TM_TLS),-e TM_TLS=$(TM_TLS),-e TM_TLS=false) \
		-v $(DIR):/app/dir:ro \
		$(DOCKER_IMAGE) scan-dir /app/dir

monitor: ## Start real-time monitoring
	@echo "$(GREEN)🛡️ Starting real-time monitoring...$(NC)"
	@if [ ! -f $(ENV_FILE) ] && [ -z "$(TM_ENDPOINT)" ]; then \
		echo "$(RED)❌ Error: Either $(ENV_FILE) file or TM_ENDPOINT environment variable is required.$(NC)"; \
		exit 1; \
	fi
	docker run -d \
		--name tmfs-cli-monitor \
		--privileged \
		$(if $(TM_ENDPOINT),-e TM_ENDPOINT=$(TM_ENDPOINT),--env-file $(ENV_FILE)) \
		$(if $(TM_TLS),-e TM_TLS=$(TM_TLS),-e TM_TLS=false) \
		$(if $(LOCAL_PATH),-e LOCAL_PATH=$(LOCAL_PATH),-e LOCAL_PATH=/mnt/nfs-share) \
		$(if $(LOCAL_PATH),-v $(LOCAL_PATH):$(LOCAL_PATH):shared,-v nfs-share:/mnt/nfs:shared) \
		$(DOCKER_IMAGE) monitor

local: ## Start local path support mode
	@echo "$(GREEN)📁 Starting local path support mode...$(NC)"
	@if [ ! -f $(ENV_FILE) ] && [ -z "$(TM_ENDPOINT)" ]; then \
		echo "$(RED)❌ Error: Either $(ENV_FILE) file or TM_ENDPOINT environment variable is required.$(NC)"; \
		exit 1; \
	fi
	docker run -d \
		--name tmfs-cli-local \
		--privileged \
		$(if $(TM_ENDPOINT),-e TM_ENDPOINT=$(TM_ENDPOINT),--env-file $(ENV_FILE)) \
		$(if $(TM_TLS),-e TM_TLS=$(TM_TLS),-e TM_TLS=false) \
		$(if $(LOCAL_PATH),-e LOCAL_PATH=$(LOCAL_PATH),-e LOCAL_PATH=/mnt/nfs-share) \
		$(if $(LOCAL_PATH),-v $(LOCAL_PATH):$(LOCAL_PATH):shared,) \
		$(DOCKER_IMAGE) local

stop: ## Stop all containers
	@echo "$(YELLOW)🛑 Stopping all containers...$(NC)"
	docker-compose -f $(DOCKER_COMPOSE_FILE) down
	docker stop tmfs-cli-monitor tmfs-cli-local 2>/dev/null || true
	docker rm tmfs-cli-monitor tmfs-cli-local 2>/dev/null || true

logs: ## Show container logs
	@echo "$(GREEN)📋 Showing container logs...$(NC)"
	docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f

status: ## Show container status
	@echo "$(GREEN)📊 Container status:$(NC)"
	docker-compose -f $(DOCKER_COMPOSE_FILE) ps
	@echo ""
	@echo "$(GREEN)📊 Running containers:$(NC)"
	docker ps --filter "name=tmfs-cli"

test: ## Test the CLI scanner with a sample file
	@echo "$(GREEN)🧪 Testing CLI scanner...$(NC)"
	@if [ ! -f $(ENV_FILE) ] && [ -z "$(TM_ENDPOINT)" ]; then \
		echo "$(RED)❌ Error: Either $(ENV_FILE) file or TM_ENDPOINT environment variable is required.$(NC)"; \
		exit 1; \
	fi
	@echo "Creating test file..."
	@echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > test-eicar.txt
	@echo "Scanning test file..."
	@docker run --rm \
		$(if $(TM_ENDPOINT),-e TM_ENDPOINT=$(TM_ENDPOINT),--env-file $(ENV_FILE)) \
		$(if $(TM_TLS),-e TM_TLS=$(TM_TLS),-e TM_TLS=false) \
		-v $(PWD)/test-eicar.txt:/app/test-eicar.txt:ro \
		$(DOCKER_IMAGE) scan /app/test-eicar.txt
	@echo "Cleaning up test file..."
	@rm -f test-eicar.txt

test-local: ## Test with local endpoint configuration
	@echo "$(GREEN)🧪 Testing local endpoint configuration...$(NC)"
	@./test.sh

setup: ## Initial setup - create .env file template
	@echo "$(GREEN)⚙️ Creating .env file template...$(NC)"
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)⚠️ $(ENV_FILE) already exists. Skipping...$(NC)"; \
	else \
		echo "# Trend Vision One CLI Configuration" > $(ENV_FILE); \
		echo "" >> $(ENV_FILE); \
		echo "# Required: Your Trend Vision One API Key" >> $(ENV_FILE); \
		echo "TM_API_KEY=your-api-key-here" >> $(ENV_FILE); \
		echo "" >> $(ENV_FILE); \
		echo "# Optional: Vision One Configuration" >> $(ENV_FILE); \
		echo "TM_REGION=us-east-1" >> $(ENV_FILE); \
		echo "TM_ENDPOINT=" >> $(ENV_FILE); \
		echo "TM_TLS=true" >> $(ENV_FILE); \
		echo "TM_TIMEOUT=300" >> $(ENV_FILE); \
		echo "" >> $(ENV_FILE); \
		echo "# NFS Configuration (if using NFS)" >> $(ENV_FILE); \
		echo "NFS_SERVER=192.168.200.10" >> $(ENV_FILE); \
		echo "NFS_SHARE=/mnt/nfs_share" >> $(ENV_FILE); \
		echo "" >> $(ENV_FILE); \
		echo "# Monitoring Configuration" >> $(ENV_FILE); \
		echo "ACTION=quarantine" >> $(ENV_FILE); \
		echo "SCAN_INTERVAL=30" >> $(ENV_FILE); \
		echo "QUARANTINE_DIR=quarantine" >> $(ENV_FILE); \
		echo "$(GREEN)✅ Created $(ENV_FILE) template. Please edit it with your API key.$(NC)"; \
	fi

version: ## Show version information
	@echo "$(GREEN)📋 Version Information:$(NC)"
	@echo "Docker Image: $(DOCKER_IMAGE)"
	@echo "Docker Compose File: $(DOCKER_COMPOSE_FILE)"
	@echo "Environment File: $(ENV_FILE)"
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(GREEN)✅ Environment file exists$(NC)"; \
	else \
		echo "$(RED)❌ Environment file missing$(NC)"; \
	fi 