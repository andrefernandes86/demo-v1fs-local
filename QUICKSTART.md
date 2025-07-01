# Quick Start Guide - Trend Vision One File Security Scanner

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Docker installed
- Git installed
- Local Trend Micro Vision One File Security endpoint running

### Step 1: Clone and Build

```bash
# Clone the repository
git clone https://github.com/andrefernandes86/demo-v1fs-local.git
cd demo-v1fs-local

# Build the Docker image
docker build -t tmfs-scanner .
```

### Step 2: Test the Setup

```bash
# Make test script executable
chmod +x test.sh

# Run comprehensive tests
./test.sh
```

### Step 3: Start Real-time Monitoring

```bash
# Start monitoring your local path
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e LOCAL_PATH=/mnt/nfs-share \
  -e ACTION=quarantine \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-scanner monitor
```

### Step 4: Check Status

```bash
# View logs
docker logs -f tmfs-monitor

# Check container status
docker ps | grep tmfs-monitor
```

## 📁 Repository Structure

```
demo-v1fs-local/
├── Dockerfile              # Main Docker image
├── docker-compose.yml      # Docker Compose configuration
├── Makefile               # Easy commands and shortcuts
├── entrypoint.sh          # Container entrypoint script
├── realtime-monitor.sh    # Real-time monitoring script
├── tmfs-wrapper.sh        # CLI wrapper script
├── test.sh               # Comprehensive test script
├── README.md             # Detailed documentation
├── DEPLOYMENT-GUIDE.md   # Deployment instructions
├── files/                # Sample files directory
├── .gitignore           # Git ignore rules
└── .dockerignore        # Docker ignore rules
```

## 🔧 Key Features

- ✅ **Local Path Monitoring**: Monitor `/mnt/nfs-share` (configurable)
- ✅ **Real-time Scanning**: Continuous file monitoring
- ✅ **Multiple Actions**: Quarantine, delete, or report only
- ✅ **Easy Commands**: Use `make` for common operations
- ✅ **Comprehensive Testing**: Built-in test suite
- ✅ **Docker Ready**: Complete containerization

## 🎯 Common Commands

```bash
# Build the image
make build

# Start monitoring
make monitor LOCAL_PATH=/mnt/nfs-share TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false

# Scan a single file
make scan FILE=/path/to/file TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false

# Stop all containers
make stop

# View logs
make logs

# Run tests
make test-local
```

## 📖 Documentation

- **README.md**: Complete technical documentation
- **DEPLOYMENT-GUIDE.md**: Step-by-step deployment instructions
- **test.sh**: Comprehensive test script with examples

## 🔗 Repository

**GitHub**: https://github.com/andrefernandes86/demo-v1fs-local

---

**Ready to deploy!** 🚀 