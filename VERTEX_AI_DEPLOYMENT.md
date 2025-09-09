# Travel Concierge - Vertex AI Agent Engine Deployment

This guide explains how to deploy the Travel Concierge application directly to Google Cloud's Vertex AI Agent Engine.

## Prerequisites

1. **Google Cloud Project** with the following APIs enabled:
   - Vertex AI API
   - Cloud Storage API
   - Cloud Build API (for automated deployment)

2. **Authentication Setup**:
   ```bash
   # Option 1: Application Default Credentials (recommended for local development)
   gcloud auth application-default login
   
   # Option 2: Service Account Key (for production/CI)
   # Download service account key and place as credentials.json
   ```

3. **Required Environment Variables**:
   ```bash
   export GOOGLE_CLOUD_PROJECT=your-project-id
   export GOOGLE_CLOUD_LOCATION=us-central1
   export GOOGLE_CLOUD_STORAGE_BUCKET=your-bucket-name
   export GOOGLE_PLACES_API_KEY=your-places-api-key
   ```

## Quick Deployment

### Method 1: Direct Deployment (Recommended)

1. **Install deployment dependencies**:
   ```bash
   poetry install --with deployment
   ```

2. **Deploy to Vertex AI**:
   ```bash
   poetry run python deployment/deploy.py --create
   ```

3. **Test the deployment**:
   ```bash
   # Use the resource ID returned from the create command
   poetry run python deployment/deploy.py --quicktest --resource_id=projects/YOUR_PROJECT/locations/us-central1/reasoningEngines/AGENT_ID
   ```

### Method 2: Automated Deployment with Cloud Build

1. **Set up Cloud Build trigger**:
   ```bash
   # Create a Cloud Build trigger
   gcloud builds triggers create github \
     --repo-name=travel-concierge \
     --repo-owner=YOUR_GITHUB_USERNAME \
     --branch-pattern="^main$" \
     --build-config=cloudbuild.yaml
   ```

2. **Deploy via Git push**:
   ```bash
   git push origin main
   # This will automatically trigger the Cloud Build pipeline
   ```

## Deployment Process

The deployment process involves several steps:

1. **Code Packaging**: The agent code is packaged into a ZIP file
2. **GCS Upload**: The package is uploaded to Google Cloud Storage
3. **Agent Engine Creation**: A new Reasoning Engine resource is created
4. **Configuration**: The agent is configured with the appropriate settings
5. **Deployment**: The agent is deployed and made available for queries

## Configuration Options

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `GOOGLE_CLOUD_PROJECT` | Your Google Cloud project ID | Yes | - |
| `GOOGLE_CLOUD_LOCATION` | Deployment location | No | `us-central1` |
| `GOOGLE_CLOUD_STORAGE_BUCKET` | GCS bucket for agent code | Yes | - |
| `GOOGLE_PLACES_API_KEY` | Google Places API key | Yes | - |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account key | No | `credentials.json` |

### Command Line Options

```bash
python deployment/deploy.py --help

Options:
  --create              Create a new agent deployment
  --delete              Delete an existing agent deployment
  --quicktest           Quick test of the deployed agent
  --resource_id ID      Resource ID for delete or test operations
  --project_id ID       Google Cloud Project ID (overrides env var)
  --location LOCATION   Google Cloud location (default: us-central1)
  --bucket BUCKET       GCS bucket name (overrides env var)
  --display_name NAME   Display name for the agent
```

## Testing Your Deployment

### Quick Test
```bash
python deployment/deploy.py --quicktest --resource_id=YOUR_RESOURCE_ID
```

### Custom Test Query
```python
# You can modify the test query in deploy.py or create a custom test script
test_query = "Plan a 5-day trip to Tokyo with budget of $2000"
```

## Monitoring and Management

### View Agent Status
```bash
# List all reasoning engines in your project
gcloud ai reasoning-engines list --region=us-central1
```

### View Logs
```bash
# View agent logs
gcloud logging read "resource.type=aiplatform.googleapis.com/ReasoningEngine" --limit=50
```

### Delete Agent
```bash
python deployment/deploy.py --delete --resource_id=YOUR_RESOURCE_ID
```

## Production Considerations

### Security
1. **Use Service Accounts**: Create dedicated service accounts with minimal required permissions
2. **IAM Roles**: Assign only necessary roles (Vertex AI User, Storage Object Admin)
3. **Network Security**: Configure VPC and firewall rules as needed

### Performance
1. **Resource Allocation**: Monitor CPU and memory usage
2. **Scaling**: Configure auto-scaling based on demand
3. **Caching**: Implement appropriate caching strategies

### Monitoring
1. **Cloud Monitoring**: Set up alerts for errors and performance metrics
2. **Logging**: Configure structured logging for better observability
3. **Tracing**: Use Cloud Trace for request tracing

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   ```bash
   # Verify authentication
   gcloud auth list
   gcloud config get-value project
   ```

2. **Permission Errors**:
   ```bash
   # Check required permissions
   gcloud projects get-iam-policy YOUR_PROJECT_ID
   ```

3. **Deployment Failures**:
   ```bash
   # Check Cloud Build logs
   gcloud builds list --limit=5
   gcloud builds log BUILD_ID
   ```

4. **Agent Not Responding**:
   ```bash
   # Check agent status
   gcloud ai reasoning-engines describe YOUR_RESOURCE_ID --region=us-central1
   ```

### Debug Mode
```bash
# Enable debug logging
export GOOGLE_CLOUD_LOGGING_LEVEL=DEBUG
python deployment/deploy.py --create
```

## Cost Optimization

1. **Resource Management**: Delete unused agents to avoid charges
2. **Monitoring**: Set up billing alerts
3. **Optimization**: Use appropriate machine types for your workload

## Support

For issues related to:
- **Vertex AI**: Check [Vertex AI documentation](https://cloud.google.com/vertex-ai/docs)
- **Agent Engine**: See [Agent Engine documentation](https://cloud.google.com/vertex-ai/docs/agent-builder/agent-engine)
- **This Application**: Check the project's GitHub issues
