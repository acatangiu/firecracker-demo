#!/bin/bash -e
SB_ID="${1:-0}" # Default to sb_id=0

#API_SOCKET="/tmp/firecracker-sb${SB_ID}.sock"
API_SOCKET="$PWD/api.socket"
CURL=(curl --silent --show-error --unix-socket "${API_SOCKET}" --write-out "HTTP %{http_code}")

curl_put() {
    local URL_PATH="$1"
    local OUTPUT RC
    OUTPUT="$("${CURL[@]}" -X PUT --data @- "http://localhost/${URL_PATH#/}" 2>&1)"
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

curl_patch '/vm' <<EOF
{
  "state": "Paused"
}
EOF

curl_put '/snapshot/create' <<EOF
{
  "snapshot_path": "snap.file",
  "mem_file_path": "mem.file"
}
EOF

killall firecracker
sleep 1
rm -f "$API_SOCKET"
./firecracker --api-sock "$API_SOCKET" --id "${SB_ID}" &

curl_put '/snapshot/load' <<EOF
{
  "snapshot_path": "snap.file",
  "mem_file_path": "mem.file"
}
EOF

curl_patch '/vm' <<EOF
{
  "state": "Resumed"
}
EOF

