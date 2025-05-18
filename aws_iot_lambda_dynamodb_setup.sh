#!/bin/bash
# ------------------------------------------------------------------------
# Serverless IoT Data Pipeline Setup Script
# 
# AWS IoT → SNS → Lambda → DynamoDB Setup
#
# This script automates the provisioning of AWS resources required for 
# a serverless IoT setup:
#
# - Creates DynamoDB table for sensor data
# - Configures SNS topic and Lambda function
# - Deploys IoT Rule to route MQTT messages
# - Manages IAM Role (LambdaIoTRole) with necessary
#    permissions for DynamoDB and SNS access
#
# Author: Shankar Saravanan
# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Pre-Requisites
# ------------------------------------------------------------------------
TABLE_NAME="IoTData"
SNS_TOPIC="iotSensorTopic"
SNS_RULE="IoTToSNSRule"
LAMBDA_NAME="processIoTData"
LAMBDA_SCRIPT="lambda_function.py"
LAMBDA_ZIP_FILE="function.zip"
LAMBDA_ROLE="LambdaIoTRole"

echo "🔍 Fetching region"
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
  echo "❌ AWS region not configured. Please run 'aws configure' to set it."
  exit 1
fi

echo "🔍 Fetching Account ID"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
  echo "❌ Account ID not configured. Please run 'aws configure' to set it."
  exit 1
fi

echo "🔍 Checking for Lambda script file '$LAMBDA_SCRIPT'..."
if [ ! -f "$LAMBDA_SCRIPT" ]; then
  echo "❌ Lambda script '$LAMBDA_SCRIPT' not found. Please ensure it exists in the current directory."
  exit 1
fi

# ------------------------------------------------------------------------
# STEP 1 - Create DynamoDB table
# ------------------------------------------------------------------------
echo "🔍 Checking if DynamoDB table '$TABLE_NAME' exists..."

if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null; then
  echo "⚠️ Table '$TABLE_NAME' exists. Deleting it..."
  aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null

  echo "⏳ Waiting for table '$TABLE_NAME' to be deleted..."
  aws dynamodb wait table-not-exists --table-name "$TABLE_NAME" --region "$REGION" 
  echo "✅ Table '$TABLE_NAME' deleted."
  
else
  echo "✅ Table '$TABLE_NAME' does not exist. Skipping deletion."

fi

echo "🚧 Creating table '$TABLE_NAME'..."
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=timestamp,AttributeType=S \
  --key-schema AttributeName=timestamp,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "⏳ Waiting for table '$TABLE_NAME' to become active..."
aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
echo "✅ Table '$TABLE_NAME' is now ready."

# ------------------------------------------------------------------------
# STEP 2 - Create SNS Topic
# ------------------------------------------------------------------------
echo "🔍 Checking for existing SNS topic '$SNS_TOPIC'..."

# Get topic ARN (if exists)
TOPIC_ARN=$(aws sns list-topics --region "$REGION" \
  --query "Topics[?ends_with(TopicArn, ':$SNS_TOPIC')].TopicArn" \
  --output text)

if [ -n "$TOPIC_ARN" ]; then
  echo "⚠️ SNS topic '$SNS_TOPIC' exists. Deleting..."
  aws sns delete-topic --topic-arn "$TOPIC_ARN" --region "$REGION"
  echo "✅ Deleted SNS topic '$SNS_TOPIC'"
else
  echo "✅ SNS topic '$SNS_TOPIC' does not exist. Skipping deletion."
fi

echo "🚧 Creating SNS topic '$SNS_TOPIC'..."
export SNS_TOPIC_ARN=$(aws sns create-topic --name "$SNS_TOPIC" --region "$REGION" --output text)
echo "✅ Created SNS topic: $NEW_TOPIC_ARN"

# ------------------------------------------------------------------------
# STEP 3 - Setup Lambda Role
# ------------------------------------------------------------------------
# Paths for temp JSON files
TRUST_POLICY_FILE="trust-policy.json"
PERMISSION_POLICY_FILE="lambda-iot-role-policy.json"

# Check and delete existing role
echo "🔍 Checking if IAM role '$LAMBDA_ROLE' exists..."
if aws iam get-role --role-name "$LAMBDA_ROLE" &>/dev/null; then
  echo "⚠️ IAM role '$LAMBDA_ROLE' exists. Deleting..."

  # Detach all attached policies
  attached_policies=$(aws iam list-attached-role-policies --role-name "$LAMBDA_ROLE" --query "AttachedPolicies[].PolicyArn" --output text)
  for policy_arn in $attached_policies; do
    echo "🔗 Detaching policy $policy_arn"
    aws iam detach-role-policy --role-name "$LAMBDA_ROLE" --policy-arn "$policy_arn"
  done

  # Delete inline policies (if any)
  inline_policies=$(aws iam list-role-policies --role-name "$LAMBDA_ROLE" --query "PolicyNames[]" --output text)
  for policy_name in $inline_policies; do
    echo "🧹 Deleting inline policy $policy_name"
    aws iam delete-role-policy --role-name "$LAMBDA_ROLE" --policy-name "$policy_name"
  done

  aws iam delete-role --role-name "$LAMBDA_ROLE"
  echo "✅ Deleted IAM role '$LAMBDA_ROLE'"
fi

# Create new trust policy file
cat > "$TRUST_POLICY_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "iot.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
echo "🚧 Creating IAM role '$LAMBDA_ROLE'..."
aws iam create-role \
  --role-name "$LAMBDA_ROLE" \
  --assume-role-policy-document file://"$TRUST_POLICY_FILE"

echo "⏳ Waiting for IAM role propagation (10s)..."
sleep 10

# Attach permission policy
cat > "$PERMISSION_POLICY_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowDynamoDBWrite",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowSNSPublish",
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "$LAMBDA_ROLE" \
  --policy-name "LambdaIoTPermissions" \
  --policy-document file://"$PERMISSION_POLICY_FILE"

echo "⏳ Waiting for IAM role policy propagation (10s)..."
sleep 10

# Clean up temp files
rm -f "$TRUST_POLICY_FILE" "$PERMISSION_POLICY_FILE"
echo "🧼 Cleaned up temporary policy files."

echo "✅ IAM role '$LAMBDA_ROLE' created and configured successfully."

# ------------------------------------------------------------------------
# STEP 4 - Create Lambda Function
# ------------------------------------------------------------------------
echo "🔍 Checking if Lambda function '$LAMBDA_NAME' exists..."

if aws lambda get-function --function-name "$LAMBDA_NAME" --region "$REGION" &>/dev/null; then
  echo "⚠️ Lambda function '$LAMBDA_NAME' exists. Deleting..."
  aws lambda delete-function --function-name "$LAMBDA_NAME" --region "$REGION"
  echo "✅ Deleted Lambda function '$LAMBDA_NAME'."
else
  echo "✅ Lambda function '$LAMBDA_NAME' does not exist. Skipping deletion."
fi

# Package Lambda Function
zip -r "$LAMBDA_ZIP_FILE" "$LAMBDA_SCRIPT" >/dev/null
echo "📦 '$LAMBDA_ZIP_FILE' created successfully."

# Create the Lambda
LAMBDA_ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE --query "Role.Arn" --output text)
aws lambda create-function \
  --function-name $LAMBDA_NAME \
  --runtime python3.9 \
  --role $LAMBDA_ROLE_ARN \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip

# Wait for Lambda to become Active
echo "⏳ Waiting for Lambda function to become Active..."
for i in {1..10}; do
  STATUS=$(aws lambda get-function --function-name "$LAMBDA_NAME" --region "$REGION" \
    --query 'Configuration.State' --output text 2>/dev/null)

  if [ "$STATUS" = "Active" ]; then
    echo "✅ Lambda function is Active."
    break
  fi

  echo "🔄 Status: $STATUS. Retrying in 5s..."
  sleep 5
done

# delete the zip file. Its not needed anymore
rm -f function.zip

# ------------------------------------------------------------------------
# STEP 5 - Subscribe Lambda to SNS
# ------------------------------------------------------------------------
LAMBDA_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_NAME"

aws sns subscribe \
  --topic-arn $SNS_TOPIC_ARN \
  --protocol lambda \
  --notification-endpoint "$LAMBDA_ARN"

# Allow SNS to invoke Lambda
aws lambda add-permission \
  --function-name processIoTData \
  --statement-id snsInvokeLambda \
  --action "lambda:InvokeFunction" \
  --principal sns.amazonaws.com \
  --source-arn $SNS_TOPIC_ARN

# ------------------------------------------------------------------------
# STEP 6 - Create IoT Rule to publish to SNS
# ------------------------------------------------------------------------
cat > iot-rule.json <<EOF
{
  "sql": "SELECT temperature, humidity FROM 'iot/topic'",
  "ruleDisabled": false,
  "actions": [
    {
      "sns": {
        "targetArn": "$SNS_TOPIC_ARN",
        "roleArn": "$LAMBDA_ROLE_ARN",
        "messageFormat": "RAW"
      }
    }
  ]
}
EOF

aws iot create-topic-rule --rule-name SNS_RULE --topic-rule-payload file://iot-rule.json

# delete the rule file. Its not needed anymore
rm -f iot-rule.json