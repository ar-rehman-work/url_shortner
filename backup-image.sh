#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/home/ubuntu/url_shortner"
BACKUP_DIR="/home/ubuntu/image-backups"

OCI_CLI="/home/ubuntu/bin/oci"
OCI_NAMESPACE="ax7jwugk5saw"
OCI_BUCKET="url-shortner-db-backups"

TIMESTAMP="$(date -u +%Y-%m-%d_%H-%M-%S)"
BACKUP_NAME="url_shortner-web_${TIMESTAMP}.tar.gz"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
TEMP_FILE="${BACKUP_FILE}.tmp"

umask 077
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

cd "$APP_DIR"

# Export the currently deployed Docker image.
docker save url_shortner-web:latest | gzip -1 > "$TEMP_FILE"

test -s "$TEMP_FILE"
mv "$TEMP_FILE" "$BACKUP_FILE"

echo "Local image archive created: $BACKUP_FILE"

# Upload using production VM instance principal.
"$OCI_CLI" os object put \
  --namespace "$OCI_NAMESPACE" \
  --bucket-name "$OCI_BUCKET" \
  --file "$BACKUP_FILE" \
  --name "$BACKUP_NAME" \
  --auth instance_principal \
  --no-multipart

# Verify uploaded object.
"$OCI_CLI" os object head \
  --namespace "$OCI_NAMESPACE" \
  --bucket-name "$OCI_BUCKET" \
  --name "$BACKUP_NAME" \
  --auth instance_principal > /dev/null

echo "OCI image backup verified: $BACKUP_NAME"

# Remove local archive after successful upload.
rm -f "$BACKUP_FILE"

echo "Image backup completed successfully."