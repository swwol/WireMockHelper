#!/bin/bash

# Path to the JSON config file
config="${SRCROOT}/${TARGET_NAME}/wiremock_config.json"

# Function to stop and remove a container if it exists
ensure_container_stopped() {
  local container_name="$1"
  if [ "$(docker ps -aq -f name="^/${container_name}$")" ]; then
    echo "Stopping and removing existing container: $container_name"
    docker stop "$container_name" >/dev/null
    # No need to explicitly remove since --rm is used in `docker run`
  fi
}

ensure_port_available() {
  local port="$1"
  local container_id

  # Find container using the port
  container_id=$(docker ps --filter "publish=$port" --format "{{.ID}}")

  if [ -n "$container_id" ]; then
    echo "Port $port is in use by container $container_id. Stopping it..."
    docker stop "$container_id" >/dev/null
  fi
}


start_container() {
  local name="$1"
  local port="$2"

  docker run -d --rm \
    --name "$name" \
    -p "$port:8080" \
    -v "${SRCROOT}/wiremock/${name}/__files:/home/wiremock/__files" \
    -v "${SRCROOT}/wiremock/${name}/mappings:/home/wiremock/mappings" \
    wiremock/wiremock:latest \
    --global-response-templating \
    --disable-gzip \
    --verbose
}

# Loop through the JSON array from file
jq -c '.[]' "$config" | while read -r item; do
  name=$(echo "$item" | jq -r '.name')
  port=$(echo "$item" | jq -r '.port')

  ensure_container_stopped "$name"
  ensure_port_available "$port"
  start_container "$name" "$port"
done

echo "WireMock containers started"


