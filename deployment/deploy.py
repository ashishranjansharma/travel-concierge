#!/usr/bin/env python3
"""
Deployment script for Travel Concierge Agent to Vertex AI Agent Engine.

This script handles the deployment of the travel concierge agent to Google Cloud's
Vertex AI Agent Engine, including creating, testing, and deleting agent resources.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Optional

import google.cloud.aiplatform as aiplatform
from google.cloud import storage
from google.cloud.aiplatform import gapic as aip
from google.oauth2 import service_account


def get_credentials():
    """Get Google Cloud credentials from environment or service account key."""
    credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', 'credentials.json')
    
    if os.path.exists(credentials_path):
        return service_account.Credentials.from_service_account_file(credentials_path)
    else:
        # Use Application Default Credentials
        return None


def upload_to_gcs(bucket_name: str, local_path: str, gcs_path: str) -> str:
    """Upload a file to Google Cloud Storage."""
    storage_client = storage.Client(credentials=get_credentials())
    bucket = storage_client.bucket(bucket_name)
    
    blob = bucket.blob(gcs_path)
    blob.upload_from_filename(local_path)
    
    return f"gs://{bucket_name}/{gcs_path}"


def create_agent_engine(
    project_id: str,
    location: str,
    bucket_name: str,
    display_name: str = "Travel Concierge Agent"
) -> str:
    """Create a new Agent Engine resource."""
    
    # Initialize AI Platform
    aiplatform.init(project=project_id, location=location)
    
    # Upload the agent code to GCS
    print("📦 Uploading agent code to Google Cloud Storage...")
    
    # Create a temporary package for deployment
    import tempfile
    import zipfile
    
    with tempfile.NamedTemporaryFile(suffix='.zip', delete=False) as tmp_file:
        with zipfile.ZipFile(tmp_file.name, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Add all necessary files
            root_dir = Path(__file__).parent.parent
            
            # Add the travel_concierge package
            for file_path in (root_dir / 'travel_concierge').rglob('*.py'):
                arcname = file_path.relative_to(root_dir)
                zipf.write(file_path, arcname)
            
            # Add configuration files
            config_files = ['pyproject.toml', 'README.md']
            for config_file in config_files:
                config_path = root_dir / config_file
                if config_path.exists():
                    zipf.write(config_path, config_file)
        
        # Upload to GCS
        gcs_path = f"agents/travel-concierge-{int(time.time())}.zip"
        gcs_uri = upload_to_gcs(bucket_name, tmp_file.name, gcs_path)
        
        # Clean up
        os.unlink(tmp_file.name)
    
    print(f"✅ Agent code uploaded to: {gcs_uri}")
    
    # Create the Agent Engine resource
    print("🚀 Creating Agent Engine resource...")
    
    client = aip.ReasoningEngineServiceClient()
    parent = f"projects/{project_id}/locations/{location}"
    
    # Define the agent configuration
    agent_config = {
        "display_name": display_name,
        "description": "AI-powered travel concierge system with multi-agent architecture",
        "spec": {
            "package_spec": {
                "package_uri": gcs_uri,
                "python_version": "3.11",
                "executor_image_uri": f"us-docker.pkg.dev/vertex-ai/agent-builder/agent-executor:latest",
            },
            "class_methods": [
                {
                    "method_name": "travel_concierge.agent.root_agent",
                    "description": "Main travel concierge agent that orchestrates travel planning and assistance"
                }
            ]
        }
    }
    
    # Create the reasoning engine
    reasoning_engine = client.create_reasoning_engine(
        parent=parent,
        reasoning_engine=aip.ReasoningEngine(**agent_config)
    )
    
    # Wait for the operation to complete
    print("⏳ Waiting for deployment to complete...")
    operation = reasoning_engine.operation
    operation.result()  # This will block until completion
    
    # Get the final resource
    resource_name = operation.metadata.name
    print(f"✅ Agent Engine created successfully!")
    print(f"📋 Resource ID: {resource_name}")
    
    return resource_name


def test_agent_engine(resource_id: str, test_query: str = "Looking for inspirations around the Americas"):
    """Test the deployed agent with a sample query."""
    print(f"🧪 Testing agent with query: '{test_query}'")
    
    # Parse the resource ID
    parts = resource_id.split('/')
    project_id = parts[1]
    location = parts[3]
    reasoning_engine_id = parts[5]
    
    # Initialize AI Platform
    aiplatform.init(project=project_id, location=location)
    
    # Create the client
    client = aip.ReasoningEngineServiceClient()
    
    # Prepare the request
    request = aip.QueryReasoningEngineRequest(
        name=resource_id,
        query={
            "input": test_query,
            "context": {
                "user_id": "test_user",
                "session_id": "test_session"
            }
        }
    )
    
    try:
        # Query the agent
        response = client.query_reasoning_engine(request)
        
        print("✅ Agent response received:")
        for chunk in response:
            if chunk.content:
                print(f"📝 {chunk.content}")
            if chunk.metadata:
                print(f"🔍 Metadata: {chunk.metadata}")
                
    except Exception as e:
        print(f"❌ Error testing agent: {e}")
        return False
    
    return True


def delete_agent_engine(resource_id: str):
    """Delete the Agent Engine resource."""
    print(f"🗑️  Deleting Agent Engine: {resource_id}")
    
    # Parse the resource ID
    parts = resource_id.split('/')
    project_id = parts[1]
    location = parts[3]
    reasoning_engine_id = parts[5]
    
    # Initialize AI Platform
    aiplatform.init(project=project_id, location=location)
    
    # Create the client
    client = aip.ReasoningEngineServiceClient()
    
    try:
        # Delete the reasoning engine
        operation = client.delete_reasoning_engine(name=resource_id)
        operation.result()  # Wait for completion
        
        print("✅ Agent Engine deleted successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error deleting agent: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Deploy Travel Concierge Agent to Vertex AI")
    parser.add_argument("--create", action="store_true", help="Create a new agent deployment")
    parser.add_argument("--delete", action="store_true", help="Delete an existing agent deployment")
    parser.add_argument("--quicktest", action="store_true", help="Quick test of the deployed agent")
    parser.add_argument("--resource_id", type=str, help="Resource ID for delete or test operations")
    parser.add_argument("--project_id", type=str, help="Google Cloud Project ID (overrides env var)")
    parser.add_argument("--location", type=str, default="us-central1", help="Google Cloud location")
    parser.add_argument("--bucket", type=str, help="GCS bucket name (overrides env var)")
    parser.add_argument("--display_name", type=str, default="Travel Concierge Agent", help="Display name for the agent")
    
    args = parser.parse_args()
    
    # Get configuration from environment or arguments
    project_id = args.project_id or os.getenv('GOOGLE_CLOUD_PROJECT')
    bucket_name = args.bucket or os.getenv('GOOGLE_CLOUD_STORAGE_BUCKET')
    
    if not project_id:
        print("❌ Error: GOOGLE_CLOUD_PROJECT environment variable or --project_id required")
        sys.exit(1)
    
    if not bucket_name:
        print("❌ Error: GOOGLE_CLOUD_STORAGE_BUCKET environment variable or --bucket required")
        sys.exit(1)
    
    print(f"🔧 Configuration:")
    print(f"   Project ID: {project_id}")
    print(f"   Location: {args.location}")
    print(f"   GCS Bucket: {bucket_name}")
    print()
    
    if args.create:
        try:
            resource_id = create_agent_engine(
                project_id=project_id,
                location=args.location,
                bucket_name=bucket_name,
                display_name=args.display_name
            )
            print(f"\n🎉 Deployment successful!")
            print(f"📋 Resource ID: {resource_id}")
            print(f"\nTo test the agent, run:")
            print(f"python deployment/deploy.py --quicktest --resource_id={resource_id}")
            
        except Exception as e:
            print(f"❌ Error creating agent: {e}")
            sys.exit(1)
    
    elif args.quicktest:
        if not args.resource_id:
            print("❌ Error: --resource_id required for testing")
            sys.exit(1)
        
        success = test_agent_engine(args.resource_id)
        if not success:
            sys.exit(1)
    
    elif args.delete:
        if not args.resource_id:
            print("❌ Error: --resource_id required for deletion")
            sys.exit(1)
        
        success = delete_agent_engine(args.resource_id)
        if not success:
            sys.exit(1)
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
