#!/bin/bash
if [[ -d "/var/lib/rancher/rke2/server/tls" ]]; then
  dir="/var/lib/rancher/rke2/server/tls"
elif [[ -d "/var/lib/rancher/rke2/agent/tls" ]]; then
  dir="/var/lib/rancher/rke2/agent/tls"
else
  dir="/var/lib/rancher/rke2/agent/"
fi
# Loop through each .crt file in the directory
for file in "$dir"/*.crt; do
  # Extract the expiry date from the certificate
  expiry=$(openssl x509 -enddate -noout -in "$file" | cut -d= -f 2-)
  # Get the file name without the path
  filename=$(basename "$file")
  # Print the filename and expiry date in a pretty format
  printf "%-30s %s\n" "$filename:" "$expiry"
done
