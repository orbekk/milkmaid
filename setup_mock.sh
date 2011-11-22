#!/bin/bash

function set_mock() {
    MOCK_DATA="$1"
    echo "Setting up mock: ${MOCK_DATA}"
    wget -O - --post-data "${MOCK_DATA}" http://localhost:8080/_httpmock/set
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

set_mock '{
  "path": "/rest/",
  "parameters": {
    "method": ["rtm.auth.getToken"],
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "api_sig": ["ba557710fa5b4074920bc37d2467545d"],
    "frob": ["5fff5557f095e3bd34390cad777637ca1d6d47a9"]
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": "<?xml version='\'''1.0'\'' encoding='\''UTF-8'\''?>
      <rsp stat=\"ok\">
        <auth>
          <token>5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b</token>
          <perms>delete</perms>
          <user id=\"2361556\" username=\"orbekk\" fullname=\"Kjetil ??rbekk\"/>
        </auth>
      </rsp>"
  }
}'

set_mock '{
  "path": "/rest/",
  "parameters": {
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "auth_token": ["5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b"],
    "method": ["rtm.timelines.create"]
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": "<?xml version='\''1.0'\'' encoding='\''UTF-8'\''?>
      <rsp stat=\"ok\"><timeline>655876238</timeline></rsp>"
  }
}'

set_mock '{
  "path": "/rest/",
  "parameters": {
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "auth_token": ["5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b"],
    "method": ["rtm.lists.getList"]
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": "<?xml version='\''1.0'\'' encoding='\''UTF-8'\''?>
      <rsp stat=\"ok\">
        <lists>
          <list id=\"15424488\" name=\"Inbox\" deleted=\"0\" locked=\"1\" archived=\"0\" position=\"-1\" smart=\"0\" sort_order=\"0\"/>
          <list id=\"15424489\" name=\"TestList\" deleted=\"0\" locked=\"0\" archived=\"1\" position=\"0\" smart=\"0\" sort_order=\"0\"/>
          <list id=\"15424490\" name=\"TestList0\" deleted=\"0\" locked=\"0\" archived=\"1\" position=\"0\" smart=\"0\" sort_order=\"0\"/>
          <list id=\"19339107\" name=\"Due soon\" deleted=\"0\" locked=\"0\" archived=\"0\" position=\"0\" smart=\"1\" sort_order=\"0\">
            <filter>(dueWithin:\"28 days of today\")</filter>
          </list>
        </lists>
      </rsp>
   "
  }
}'
