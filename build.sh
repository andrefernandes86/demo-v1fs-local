#!/bin/bash
# Comprehensive build script for Trend Vision One File Security Docker Container
# Supports both Go SDK and CLI versions

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_help() {
    echo "🛡️ Trend Vision One File Security Docker Builder"
    echo "================================================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --go-sdk          Build Go SDK version (local endpoints)"
    echo "  --cli             Build CLI version (cloud Vision One)"
    echo "  --both            Build both versions"
    echo "  --test            Run tests after building"
    echo "  --push            Push images to registry (requires --registry)"
    echo "  --registry=REG    Docker registry for pushing images"
    echo "  --tag=TAG         Image tag (default: latest)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --go-sdk                    # Build Go SDK version only"
    echo "  $0 --cli                       # Build CLI version only"
    echo "  $0 --both --test               # Build both versions and test"
    echo "  $0 --both --push --registry=myregistry.com --tag=v1.0.0"
    echo ""
    echo "Default: Builds both versions if no option specified"
}

# Default values
BUILD_GO_SDK=false
BUILD_CLI=false
RUN_TESTS=false
PUSH_IMAGES=false
REGISTRY=""
TAG="latest"

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --go-sdk)
            BUILD_GO_SDK=true
            shift
            ;;
        --cli)
            BUILD_CLI=true
            shift
            ;;
        --both)
            BUILD_GO_SDK=true
            BUILD_CLI=true
            shift
            ;;
        --test)
            RUN_TESTS=true
            shift
            ;;
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --registry=*)
            REGISTRY="${1#*=}"
            shift
            ;;
        --tag=*)
            TAG="${1#*=}"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# If no build option specified, build both
if [ "$BUILD_GO_SDK" = false ] && [ "$BUILD_CLI" = false ]; then
    BUILD_GO_SDK=true
    BUILD_CLI=true
fi

echo "🛡️ Trend Vision One File Security Docker Builder"
echo "================================================"
echo "Build Go SDK: $BUILD_GO_SDK"
echo "Build CLI: $BUILD_CLI"
echo "Run Tests: $RUN_TESTS"
echo "Push Images: $PUSH_IMAGES"
if [ -n "$REGISTRY" ]; then
    echo "Registry: $REGISTRY"
fi
echo "Tag: $TAG"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi

print_status "Docker is running"

# Build Go SDK version
if [ "$BUILD_GO_SDK" = true ]; then
    echo ""
    print_info "Building Go SDK version..."
    
    # Build the image
    if docker build -t tmfs-scanner:$TAG .; then
        print_status "Go SDK version built successfully"
        
        # Tag for registry if specified
        if [ -n "$REGISTRY" ]; then
            docker tag tmfs-scanner:$TAG $REGISTRY/tmfs-scanner:$TAG
            print_status "Tagged for registry: $REGISTRY/tmfs-scanner:$TAG"
        fi
    else
        print_error "Failed to build Go SDK version"
        exit 1
    fi
fi

# Build CLI version
if [ "$BUILD_CLI" = true ]; then
    echo ""
    print_info "Building CLI version..."
    
    # Build the CLI image
    if docker build -f Dockerfile.cli -t tmfs-cli-scanner:$TAG .; then
        print_status "CLI version built successfully"
        
        # Tag for registry if specified
        if [ -n "$REGISTRY" ]; then
            docker tag tmfs-cli-scanner:$TAG $REGISTRY/tmfs-cli-scanner:$TAG
            print_status "Tagged for registry: $REGISTRY/tmfs-cli-scanner:$TAG"
        fi
    else
        print_error "Failed to build CLI version"
        exit 1
    fi
fi

# Run tests if requested
if [ "$RUN_TESTS" = true ]; then
    echo ""
    print_info "Running tests..."
    
    if [ "$BUILD_GO_SDK" = true ]; then
        echo "Testing Go SDK version..."
        if make test; then
            print_status "Go SDK tests passed"
        else
            print_warning "Go SDK tests failed"
        fi
    fi
    
    if [ "$BUILD_CLI" = true ]; then
        echo "Testing CLI version..."
        if make -f Makefile.cli test-local; then
            print_status "CLI tests passed"
        else
            print_warning "CLI tests failed"
        fi
    fi
fi

# Push images if requested
if [ "$PUSH_IMAGES" = true ]; then
    if [ -z "$REGISTRY" ]; then
        print_error "Registry must be specified with --registry when using --push"
        exit 1
    fi
    
    echo ""
    print_info "Pushing images to registry..."
    
    if [ "$BUILD_GO_SDK" = true ]; then
        echo "Pushing Go SDK version..."
        if docker push $REGISTRY/tmfs-scanner:$TAG; then
            print_status "Go SDK version pushed successfully"
        else
            print_error "Failed to push Go SDK version"
            exit 1
        fi
    fi
    
    if [ "$BUILD_CLI" = true ]; then
        echo "Pushing CLI version..."
        if docker push $REGISTRY/tmfs-cli-scanner:$TAG; then
            print_status "CLI version pushed successfully"
        else
            print_error "Failed to push CLI version"
            exit 1
        fi
    fi
fi

# Show built images
echo ""
print_info "Built images:"
docker images | grep -E "(tmfs-scanner|tmfs-cli-scanner)" | head -10

echo ""
print_status "Build completed successfully!"
echo ""
echo "🚀 Next steps:"
echo ""

if [ "$BUILD_GO_SDK" = true ]; then
    echo "📦 Go SDK Version (Local Endpoints):"
    echo "  # Test single file scan"
    echo "  docker run --rm tmfs-scanner:$TAG scan /path/to/file"
    echo ""
    echo "  # Start monitoring with NFS"
    echo "  docker run -d --privileged \\"
    echo "    -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \\"
    echo "    -e TLS=false \\"
    echo "    -e ACTION=quarantine \\"
    echo "    -v nfs-share:/mnt/nfs:shared \\"
    echo "    tmfs-scanner:$TAG monitor"
    echo ""
fi

if [ "$BUILD_CLI" = true ]; then
    echo "📦 CLI Version (Cloud Vision One):"
    echo "  # Setup environment first"
    echo "  make -f Makefile.cli setup"
    echo "  # Edit .env file with your TM_API_KEY"
    echo ""
    echo "  # Test single file scan"
    echo "  docker run --rm --env-file .env tmfs-cli-scanner:$TAG scan /path/to/file"
    echo ""
    echo "  # Start monitoring with NFS"
    echo "  docker run -d --privileged \\"
    echo "    --env-file .env \\"
    echo "    -e ACTION=quarantine \\"
    echo "    -v nfs-share:/mnt/nfs:shared \\"
    echo "    tmfs-cli-scanner:$TAG monitor"
    echo ""
fi

echo "📚 Documentation:"
echo "  - README.md (Go SDK version)"
echo "  - README-CLI.md (CLI version)"
echo "  - ./test-local-endpoint.sh (Test local endpoint)"
echo "  - ./test-cli.sh (Test CLI version)" 