# Travel Concierge - Container Deployment Guide

This guide explains how to deploy the Travel Concierge application using Docker containers.

## Prerequisites

- Docker and Docker Compose installed
- Google Cloud Project with Vertex AI enabled
- Google Places API key
- (Optional) Google Cloud Storage bucket for Agent Engine deployment

## Quick Start

### 1. Environment Setup

1. Copy the environment template:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` file with your configuration:
   ```bash
   # Required: Choose your model backend
   GOOGLE_GENAI_USE_VERTEXAI=1
   
   # Required: Your Google Cloud project
   GOOGLE_CLOUD_PROJECT=your-project-id
   
   # Required: Google Places API key
   GOOGLE_PLACES_API_KEY=your-places-api-key
   
   # Optional: GCS bucket for Agent Engine
   GOOGLE_CLOUD_STORAGE_BUCKET=your-bucket-name
   ```

### 2. Authentication Setup

#### Option A: Service Account Key (Recommended for containers)
1. Create a service account in Google Cloud Console
2. Download the JSON key file
3. Place it in the project root as `credentials.json`
4. The container will automatically use it

#### Option B: Application Default Credentials
1. Run `gcloud auth application-default login` on your host
2. Mount your credentials directory:
   ```yaml
   volumes:
     - ~/.config/gcloud:/home/app/.config/gcloud:ro
   ```

### 3. Build and Run

#### Using Docker Compose (Recommended)
```bash
# Build and start the application
docker-compose up --build

# Run in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop the application
docker-compose down
```

#### Using Docker directly
```bash
# Build the image
docker build -t travel-concierge .

# Run the container
docker run -d \
  --name travel-concierge \
  -p 8000:8000 \
  --env-file .env \
  -v $(pwd)/credentials.json:/app/credentials.json:ro \
  travel-concierge
```

### 4. Access the Application

- **Web Interface**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## Production Deployment

### Using Docker Compose with Nginx

1. Start with production profile:
   ```bash
   docker-compose --profile production up -d
   ```

2. This will start both the application and nginx reverse proxy
3. Access via http://localhost (port 80)

### Environment Variables for Production

```bash
# Production environment variables
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=your-production-project
GOOGLE_CLOUD_LOCATION=us-central1
GOOGLE_PLACES_API_KEY=your-production-places-key
GOOGLE_CLOUD_STORAGE_BUCKET=your-production-bucket

# Server configuration
HOST=0.0.0.0
PORT=8000

# Scenario configuration
TRAVEL_CONCIERGE_SCENARIO=travel_concierge/profiles/itinerary_empty_default.json
```

### Security Considerations

1. **Use secrets management** for sensitive environment variables
2. **Enable HTTPS** in production (configure SSL certificates in nginx.conf)
3. **Use non-root user** (already configured in Dockerfile)
4. **Regular security updates** of base images
5. **Network security** - restrict container network access

### Scaling

For horizontal scaling, you can run multiple instances behind a load balancer:

```yaml
# docker-compose.override.yml
version: '3.8'
services:
  travel-concierge:
    deploy:
      replicas: 3
    ports:
      - "8001:8000"
      - "8002:8000" 
      - "8003:8000"
```

## Monitoring and Logging

### Health Checks
The container includes built-in health checks:
- Endpoint: `/health`
- Interval: 30 seconds
- Timeout: 10 seconds

### Logging
View application logs:
```bash
# Docker Compose
docker-compose logs -f travel-concierge

# Docker
docker logs -f travel-concierge
```

### Monitoring
Consider adding monitoring tools like:
- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Google Cloud Monitoring

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Google Cloud credentials
   - Check project permissions
   - Ensure Vertex AI API is enabled

2. **Missing Environment Variables**
   - Check `.env` file exists and is properly formatted
   - Verify all required variables are set

3. **Port Conflicts**
   - Change port mapping in docker-compose.yml
   - Check if port 8000 is already in use

4. **Memory Issues**
   - Increase Docker memory limits
   - Monitor container resource usage

### Debug Mode

Run container in debug mode:
```bash
docker run -it --rm \
  --env-file .env \
  -v $(pwd)/credentials.json:/app/credentials.json:ro \
  travel-concierge /bin/bash
```

## Customization

### Custom Scenarios
1. Create custom itinerary files in `travel_concierge/profiles/`
2. Update `TRAVEL_CONCIERGE_SCENARIO` environment variable
3. Restart the container

### Custom Configuration
1. Modify `docker-compose.yml` for your specific needs
2. Update `nginx.conf` for custom routing
3. Extend `Dockerfile` for additional dependencies

## Support

For issues and questions:
1. Check the application logs
2. Verify environment configuration
3. Review the main README.md for application-specific issues
4. Check Google Cloud Console for API-related issues
