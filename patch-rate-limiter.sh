#!/bin/bash -e
SB_ID="${1:-0}" # Default to sb_id=0

#API_SOCKET="/tmp/firecracker-sb${SB_ID}.sock"
API_SOCKET="$PWD/api.socket"
CURL=(curl --silent --show-error --unix-socket "${API_SOCKET}" --write-out "HTTP %{http_code}")

curl_patch() {
    local URL_PATH="$1"
    local OUTPUT RC
    OUTPUT="$("${CURL[@]}" -X PATCH --data @- "http://localhost/${URL_PATH#/}" 2>&1)"
    RC="$?"
    if [ "$RC" -ne 0 ]; then
        echo "Error: curl PATCH ${URL_PATH} failed with exit code $RC, output:"
        echo "$OUTPUT"
        return 1
    fi
    # Error if output doesn't end with "HTTP 2xx"
    if [[ "$OUTPUT" != *HTTP\ 2[0-9][0-9] ]]; then
        echo "Error: curl PATCH ${URL_PATH} failed with non-2xx HTTP status code, output:"
        echo "$OUTPUT"
        return 1
    fi
}

curl_patch '/network-interfaces/net1' <<EOF
{
  "iface_id": "net1",
  "tx_rate_limiter": {
    "bandwidth": {
      "size": 0,
      "refill_time": 0 
    }
  }
}
EOF

