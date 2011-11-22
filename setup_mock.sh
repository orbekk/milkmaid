#!/bin/bash

function set_mock() {
    MOCK_DATA="$1"
    echo "Setting up mock: ${MOCK_DATA}"
    wget -q -O - --post-data "${MOCK_DATA}" http://localhost:8080/_httpmock/set
}

set_mock '{
  "path": "/rest/",
  "parameters": {
    "method": ["rtm.auth.getFrob"],
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "api_sig": ["6a588857304ee35d5c79010a4e8d5848"]
    },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": "<?xml version='\''1.0'\'' encoding='\''UTF-8'\''?>
      <rsp stat=\"ok\"><frob>5fff5557f095e3bd34390cad777637ca1d6d47a9</frob></rsp>"
  }
}'
