# Travel Concierge - Docker Management Makefile

.PHONY: help build run stop clean logs test dev prod

# Default target
help:
	@echo "Travel Concierge Docker Management"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@echo "  make build     - Build the Docker image"
	@echo "  make run       - Run the container (development)"
	@echo "  make dev       - Run with docker-compose (development)"
	@echo "  make prod      - Run with docker-compose (production with nginx)"
	@echo "  make stop      - Stop all containers"
	@echo "  make clean     - Remove containers and images"
	@echo "  make logs      - View container logs"
	@echo "  make test      - Test the container build"
	@echo "  make setup     - Initial setup (copy env file)"
	@echo ""

# Build the Docker image
build:
	docker build -t travel-concierge .

# Run container directly (development)
run: build
	docker run -d \
		--name travel-concierge \
		-p 8000:8000 \
		--env-file .env \
		travel-concierge

# Run with docker-compose (development)
dev:
	docker-compose up --build

# Run with docker-compose (production)
prod:
	docker-compose --profile production up --build -d

# Stop all containers
stop:
	docker-compose down
	docker stop travel-concierge 2>/dev/null || true

# Clean up containers and images
clean: stop
	docker-compose down --rmi all --volumes --remove-orphans
	docker rmi travel-concierge 2>/dev/null || true
	docker system prune -f

# View logs
logs:
	docker-compose logs -f

# Test build (without running)
test: build
	@echo "✅ Docker image built successfully!"
	@echo "Image: travel-concierge"
	@echo "To run: make run"

# Initial setup
setup:
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "✅ Created .env file from env.example"; \
		echo "⚠️  Please edit .env with your actual configuration"; \
	else \
		echo "✅ .env file already exists"; \
	fi

# Check if Docker is running
check-docker:
	@docker version >/dev/null 2>&1 || (echo "❌ Docker is not running. Please start Docker Desktop." && exit 1)

# Full development setup
setup-dev: check-docker setup
	@echo "✅ Development environment ready!"
	@echo "Next steps:"
	@echo "1. Edit .env with your configuration"
	@echo "2. Run: make dev"
