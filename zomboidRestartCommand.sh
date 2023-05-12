#!/bin/bash

screen -S zomboid -X stuff 'quit'

sleep 15

screen -S zomboid -X stuff '/opt/pzserver/start-server.sh -servername servertest-2'
