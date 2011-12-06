#!/bin/bash

# Requires the following directory structure:
#
#  HttpMock/  # Contains HttpMock project
#  HttpMock/milkmaid # Contains milkmaid
#
# Run from the HttpMock directory.

(sbt "run --port 8080" 2>&1) > httpmock.log  &

# We would like to do this, but unfortunately the java vm detatches and cannot
# be killed with this PID.
declare -r HTTPMOCK_PID=$!
echo ${HTTPMOCK_PID} > httpmock.pid

function wait_for_httpmock() {
    STATUS=""
    while [[ "${STATUS}" != "online" ]]; do
        STATUS=$(wget -q -O - http://localhost:8080/_httpmock/status)
        sleep 1
    done
}

wait_for_httpmock

function set_mock() {
    MOCK_DATA="$1"
    # echo "Setting up mock: ${MOCK_DATA}"
    wget -q -O - --post-data "${MOCK_DATA}" http://localhost:8080/_httpmock/set
}

####
# Authentication: getFrob
#
# When milkmaid connects to the RTM service, it requests a frob. This mock 
# responds with a frob. The frob is used as a part of an URL that the user has
# to enter in his/her web browser to grant milkmaid access to the RTM service.
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
      <rsp stat=\"ok\"><frob>test_frob</frob></rsp>"
  }
}'

####
# Authentication: getToken
#
# Milkmaid then asks the RTM service for a token. We pretend that the user was
# granted a token.
set_mock '{
  "path": "/rest/",
  "parameters": {
    "method": ["rtm.auth.getToken"],
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "frob": ["test_frob"]
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": "<?xml version='\'''1.0'\'' encoding='\''UTF-8'\''?>
      <rsp stat=\"ok\">
        <auth>
          <token>5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b</token>
          <perms>delete</perms>
          <user id=\"1\" username=\"test_user\" fullname=\"Test User\"/>
        </auth>
      </rsp>"
  }
}'

####
# Timelines can be used to undo certain actions.
#
# We return a timeline because milkmaid asks for them, but we don't perform any
# checking of this functionality.
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

####
# This is used to return the user's list of to-do lists.
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
          <list id=\"100\" name=\"TestList\" deleted=\"0\" locked=\"0\" archived=\"1\" position=\"0\" smart=\"0\" sort_order=\"0\"/>
          <list id=\"101\" name=\"TestList0\" deleted=\"0\" locked=\"0\" archived=\"1\" position=\"0\" smart=\"0\" sort_order=\"0\"/>
          <list id=\"19339107\" name=\"Due soon\" deleted=\"0\" locked=\"0\" archived=\"0\" position=\"0\" smart=\"1\" sort_order=\"0\">
            <filter>(dueWithin:\"28 days of today\")</filter>
          </list>
        </lists>
      </rsp>
   "
  }
}'

####
# This returns the TestList to-do list.
set_mock '{
  "path": "/rest/",
  "parameters": {
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "auth_token": ["5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b"],
    "method": ["rtm.tasks.getList"],
    "list_id": ["100"]
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": 
    "
    <?xml version=\"1.0\" encoding=\"utf8\"?>
    <rsp stat=\"ok\">
      <tasks rev=\"r332ijaf32ock08w8skcwcgo00g8wsc\">
        <list id=\"100\">
          <taskseries id=\"1000\" created=\"2011-06-03T13:21:22Z\" modified=\"2011-07-22T17:49:33Z\" name=\"test task\" source=\"js\" url=\"\" location_id=\"\">
            <tags>
              <tag>test_list</tag>
            </tags>
            <participants/>
            <notes/>
            <task id=\"1005\" due=\"2011-06-30T22:00:00Z\" has_due_time=\"0\" added=\"2011-06-03T13:21:22Z\" completed=\"\" deleted=\"\" priority=\"N\" postponed=\"11\" estimate=\"\"/>
          </taskseries>
        </list>
      </tasks>
    </rsp>
    "
  }
}'

####
# This mock responds to an add request.
#
# The task "new test task" is added.
set_mock '{
  "path": "/rest/",
  "parameters": {
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "auth_token": ["5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b"],
    "method": ["rtm.tasks.add"],
    "name": ["new test task"],
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": 
    "
    <?xml version=\"1.0\" encoding=\"utf8\"?>
    <rsp stat=\"ok\">
      <transaction id=\"5319886148\" undoable=\"0\"/>
      <list id=\"100\">
        <taskseries id=\"141430077\" created=\"2011-12-06T18:38:11Z\" modified=\"2011-12-06T18:38:11Z\" name=\"new test task\" source=\"api\" url=\"\" location_id=\"\">
          <tags/>
          <participants/>
          <notes/>
          <task id=\"222284206\" due=\"\" has_due_time=\"0\" added=\"2011-12-06T18:38:11Z\" completed=\"\" deleted=\"\" priority=\"N\" postponed=\"0\" estimate=\"\"/>
        </taskseries>
      </list>
    </rsp>
    "
  }
}'


####
# This mock responds to a complete action.
#
# The "test task" returned in the list TestList is being completed.
set_mock '{
  "path": "/rest/",
  "parameters": {
    "api_key": ["31308536ffed80061df846c3a4564a27"],
    "auth_token": ["5705ff10e0fa215d5b4cffeb07cdeb2f8cbe798b"],
    "method": ["rtm.tasks.complete"],
    "list_id": ["100"],
    "taskseries_id": ["1000"],
    "task_id": ["1005"]
  },
  "response": {
    "headers": {"Content-Type": "text/xml; charset=utf-8"},
    "content": 
    "
    <?xml version=\"1.0\" encoding=\"utf8\"?>
    <rsp stat=\"ok\">
      <transaction id=\"5319929527\" undoable=\"1\"/>
      <list id=\"100\">
        <taskseries id=\"1000\" created=\"2011-12-06T18:44:51Z\" modified=\"2011-12-06T18:45:48Z\" name=\"test task\" source=\"api\" url=\"\" location_id=\"\">
          <tags>
            <tag>test</tag>
          </tags>
          <participants/>
          <notes/>
          <task id=\"1005\" due=\"\" has_due_time=\"0\" added=\"2011-12-06T18:44:51Z\" completed=\"2011-12-06T18:45:48Z\" deleted=\"\" priority=\"N\" postponed=\"0\" estimate=\"\"/>
        </taskseries>
      </list>
    </rsp>
    "
  }
}'

function assert_success() {
    if [[ "$1" != "0" ]]; then
        echo "Failed at line $2"
        echo "Not 0: $1"
        exit 1
    fi
}

pushd milkmaid
HOME=`pwd`
rm .milkmaid || true

# Initialization
bundle exec ruby bin/milkmaid auth start
assert_success $? $LINENO
bundle exec ruby bin/milkmaid auth finish
assert_success $? $LINENO

# List tasks test
bundle exec ruby bin/milkmaid list | grep "TestList"
assert_success $? $LINENO
bundle exec ruby bin/milkmaid task -l 2 | grep "test task"
assert_success $? $LINENO

# Add task test
bundle exec ruby bin/milkmaid task add "new test task"
assert_success $? $LINENO

# Complete task test
bundle exec ruby bin/milkmaid task complete -l 2 1
assert_success $? $LINENO

popd

echo "Test PASSED."

# Kill the server.
pkill -f "sbt-launch.jar run --port 8080"
