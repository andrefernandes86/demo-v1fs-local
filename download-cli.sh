#!/bin/bash

echo "=== Trend Micro Vision One CLI Download Helper ==="
echo ""
echo "The Trend Micro Vision One CLI needs to be downloaded manually from your Vision One console."
echo ""
echo "Follow these steps:"
echo ""
echo "1. Log into your Trend Micro Vision One console"
echo "2. Go to Administration > Tools > CLI"
echo "3. Download the Linux AMD64 version"
echo "4. Rename the downloaded file to 'tmfs'"
echo "5. Place it in this directory"
echo ""
echo "Alternative method (if you have the CLI installed locally):"
echo ""

# Check if tmfs is already in the current directory
if [ -f "./tmfs" ]; then
    echo "✅ Found 'tmfs' file in current directory"
    echo "You can now build the Docker image with: docker build -t tmfs-scanner ."
else
    echo "❌ 'tmfs' file not found in current directory"
    echo ""
    echo "If you have the CLI installed locally, you can copy it:"
    echo "cp /path/to/your/tmfs ./tmfs"
    echo ""
    echo "Or download it from your Vision One console and place it here."
fi

echo ""
echo "For more information, visit:"
echo "https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-deploying-cli" 