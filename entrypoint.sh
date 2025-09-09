#!/bin/bash
set -e

# Function to check if required environment variables are set
check_env_vars() {
    local missing_vars=()
    
    if [ "$GOOGLE_GENAI_USE_VERTEXAI" = "1" ]; then
        [ -z "$GOOGLE_CLOUD_PROJECT" ] && missing_vars+=("GOOGLE_CLOUD_PROJECT")
        [ -z "$GOOGLE_CLOUD_LOCATION" ] && missing_vars+=("GOOGLE_CLOUD_LOCATION")
    else
        [ -z "$GOOGLE_API_KEY" ] && missing_vars+=("GOOGLE_API_KEY")
    fi
    
    [ -z "$GOOGLE_PLACES_API_KEY" ] && missing_vars+=("GOOGLE_PLACES_API_KEY")
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "Error: Missing required environment variables:"
        printf '  - %s\n' "${missing_vars[@]}"
        echo ""
        echo "Please set these variables in your .env file or environment."
        echo "See env.example for reference."
        exit 1
    fi
}

# Function to authenticate with Google Cloud (if using Vertex AI)
setup_gcloud_auth() {
    if [ "$GOOGLE_GENAI_USE_VERTEXAI" = "1" ]; then
        echo "Setting up Google Cloud authentication..."
        
        if [ -f "/app/credentials.json" ]; then
            echo "Using service account key file for authentication..."
            export GOOGLE_APPLICATION_CREDENTIALS="/app/credentials.json"
        else
            echo "No credentials file found. Make sure you have:"
            echo "1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable, or"
            echo "2. Mounted a credentials.json file, or"
            echo "3. Run 'gcloud auth application-default login' on the host"
        fi
    fi
}

# Function to validate scenario file
validate_scenario() {
    if [ -n "$TRAVEL_CONCIERGE_SCENARIO" ]; then
        if [ ! -f "$TRAVEL_CONCIERGE_SCENARIO" ]; then
            echo "Warning: Scenario file '$TRAVEL_CONCIERGE_SCENARIO' not found."
            echo "Using default empty itinerary."
            export TRAVEL_CONCIERGE_SCENARIO="travel_concierge/profiles/itinerary_empty_default.json"
        fi
    fi
}

# Main initialization
main() {
    echo "Starting Travel Concierge container..."
    
    # Check required environment variables
    check_env_vars
    
    # Setup Google Cloud authentication
    setup_gcloud_auth
    
    # Validate scenario file
    validate_scenario
    
    echo "Environment validation completed successfully!"
    echo "Starting Travel Concierge application..."
    
    # Execute the main command
    exec "$@"
}

# Run main function with all arguments
main "$@"
