#!/bin/bash

# Script to set up S3 backend for Terraform state
# Usage: ./setup-s3-backend.sh <bucket-name> [region] [project-name]

set -e

BUCKET_NAME=$1
REGION=${2:-us-east-1}
PROJECT_NAME=${3:-nightscout}

if [ -z "$BUCKET_NAME" ]; then
    echo "Usage: $0 <bucket-name> [region] [project-name]"
    echo "Example: $0 my-terraform-state-bucket us-east-1 nightscout"
    exit 1
fi

echo "Setting up S3 backend with:"
echo "  Bucket: $BUCKET_NAME"
echo "  Region: $REGION"
echo "  Project: $PROJECT_NAME"
echo ""

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH"
    exit 1
fi

# Create S3 bucket
echo "Creating S3 bucket..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists"
else
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "Created bucket $BUCKET_NAME"
fi

# Enable versioning
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ""
echo "✅ S3 backend setup complete!"
echo ""
