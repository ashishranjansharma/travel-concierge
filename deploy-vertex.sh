#!/bin/bash

# Travel Concierge - Vertex AI Deployment Script
# This script provides an easy way to deploy the travel concierge to Vertex AI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check environment variables
check_env_vars() {
    local missing_vars=()
    
    [ -z "$GOOGLE_CLOUD_PROJECT" ] && missing_vars+=("GOOGLE_CLOUD_PROJECT")
    [ -z "$GOOGLE_CLOUD_STORAGE_BUCKET" ] && missing_vars+=("GOOGLE_CLOUD_STORAGE_BUCKET")
    [ -z "$GOOGLE_PLACES_API_KEY" ] && missing_vars+=("GOOGLE_PLACES_API_KEY")
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required environment variables:"
        printf '  - %s\n' "${missing_vars[@]}"
        echo ""
        print_status "Please set these variables in your .env file or environment:"
        echo "  export GOOGLE_CLOUD_PROJECT=your-project-id"
        echo "  export GOOGLE_CLOUD_STORAGE_BUCKET=your-bucket-name"
        echo "  export GOOGLE_PLACES_API_KEY=your-places-api-key"
        echo ""
        print_status "You can also copy env.example to .env and edit it:"
        echo "  cp .env.example .env"
        echo "  # Edit .env with your values"
        return 1
    fi
    
    return 0
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if poetry is installed
    if ! command_exists poetry; then
        print_error "Poetry is not installed. Please install it first:"
        echo "  curl -sSL https://install.python-poetry.org | python3 -"
        return 1
    fi
    
    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "Google Cloud CLI is not installed. Please install it first:"
        echo "  https://cloud.google.com/sdk/docs/install"
        return 1
    fi
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with Google Cloud. Please run:"
        echo "  gcloud auth application-default login"
        return 1
    fi
    
    # Check if project is set
    local current_project=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$current_project" ]; then
        print_warning "No default project set. Using GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"
        gcloud config set project "$GOOGLE_CLOUD_PROJECT"
    fi
    
    print_success "Prerequisites check passed"
    return 0
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if [ ! -f "pyproject.toml" ]; then
        print_error "pyproject.toml not found. Are you in the correct directory?"
        return 1
    fi
    
    # Install dependencies
    poetry install --with deployment
    
    print_success "Dependencies installed"
}

# Function to create GCS bucket if it doesn't exist
create_bucket_if_needed() {
    print_status "Checking GCS bucket..."
    
    if gsutil ls "gs://$GOOGLE_CLOUD_STORAGE_BUCKET" >/dev/null 2>&1; then
        print_success "GCS bucket exists: gs://$GOOGLE_CLOUD_STORAGE_BUCKET"
    else
        print_status "Creating GCS bucket: gs://$GOOGLE_CLOUD_STORAGE_BUCKET"
        gsutil mb "gs://$GOOGLE_CLOUD_STORAGE_BUCKET"
        print_success "GCS bucket created"
    fi
}

# Function to deploy the agent
deploy_agent() {
    print_status "Deploying agent to Vertex AI..."
    
    # Run the deployment script
    poetry run python deployment/deploy.py --create
    
    print_success "Agent deployed successfully!"
}

# Function to test the agent
test_agent() {
    local resource_id="$1"
    
    if [ -z "$resource_id" ]; then
        print_warning "No resource ID provided for testing"
        return 0
    fi
    
    print_status "Testing deployed agent..."
    poetry run python deployment/deploy.py --quicktest --resource_id="$resource_id"
    
    print_success "Agent test completed"
}

# Main function
main() {
    echo "🚀 Travel Concierge - Vertex AI Deployment"
    echo "=========================================="
    echo ""
    
    # Check environment variables
    if ! check_env_vars; then
        exit 1
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Install dependencies
    if ! install_dependencies; then
        exit 1
    fi
    
    # Create bucket if needed
    if ! create_bucket_if_needed; then
        exit 1
    fi
    
    # Deploy the agent
    if ! deploy_agent; then
        exit 1
    fi
    
    echo ""
    print_success "🎉 Deployment completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Test your agent using the resource ID provided above"
    echo "2. Monitor your agent in the Google Cloud Console"
    echo "3. Set up monitoring and alerts as needed"
    echo ""
    print_status "For more information, see VERTEX_AI_DEPLOYMENT.md"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Travel Concierge - Vertex AI Deployment Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --test ID      Test an existing deployment"
        echo "  --delete ID    Delete an existing deployment"
        echo ""
        echo "Environment Variables:"
        echo "  GOOGLE_CLOUD_PROJECT         Your Google Cloud project ID"
        echo "  GOOGLE_CLOUD_STORAGE_BUCKET  GCS bucket for agent code"
        echo "  GOOGLE_PLACES_API_KEY        Google Places API key"
        echo "  GOOGLE_CLOUD_LOCATION        Deployment location (default: us-central1)"
        echo ""
        exit 0
        ;;
    --test)
        if [ -z "$2" ]; then
            print_error "Resource ID required for testing"
            exit 1
        fi
        test_agent "$2"
        ;;
    --delete)
        if [ -z "$2" ]; then
            print_error "Resource ID required for deletion"
            exit 1
        fi
        print_status "Deleting agent: $2"
        poetry run python deployment/deploy.py --delete --resource_id="$2"
        print_success "Agent deleted"
        ;;
    *)
        main
        ;;
esac
