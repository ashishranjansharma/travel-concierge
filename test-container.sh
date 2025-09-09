#!/bin/bash

# Travel Concierge Container Test Script

set -e

echo "🧪 Testing Travel Concierge Container Setup"
echo "=========================================="

# Check if Docker is running
echo "📋 Checking Docker..."
if ! docker version >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi
echo "✅ Docker is running"

# Check if .env file exists
echo "📋 Checking environment configuration..."
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "✅ Created .env file from template"
    echo "⚠️  Please edit .env with your actual configuration before running the container"
else
    echo "✅ .env file found"
fi

# Test Docker build
echo "📋 Testing Docker build..."
if docker build -t travel-concierge-test . >/dev/null 2>&1; then
    echo "✅ Docker build successful"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Test container startup (without running the full application)
echo "📋 Testing container startup..."
if docker run --rm \
    --name travel-concierge-test \
    --env-file .env \
    travel-concierge-test \
    /bin/bash -c "echo 'Container startup test successful'" >/dev/null 2>&1; then
    echo "✅ Container startup test successful"
else
    echo "❌ Container startup test failed"
    exit 1
fi

# Cleanup test image
echo "📋 Cleaning up test image..."
docker rmi travel-concierge-test >/dev/null 2>&1 || true

echo ""
echo "🎉 All tests passed! Your container setup is ready."
echo ""
echo "Next steps:"
echo "1. Edit .env with your actual configuration"
echo "2. Run: make dev (for development) or make prod (for production)"
echo "3. Access the application at http://localhost:8000"
