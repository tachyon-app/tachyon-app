#!/bin/bash

# Build and run Tachyon
echo "🔨 Building Tachyon..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "🚀 Launching Tachyon..."
    echo ""
    echo "Press Cmd+Space to open the search bar"
    echo "Press Cmd+, to open settings"
    echo "Press Ctrl+C to quit"
    echo ""
    
    # Run the app
    .build/debug/Tachyon
else
    echo "❌ Build failed"
    exit 1
fi
