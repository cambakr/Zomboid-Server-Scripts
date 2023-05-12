#!/bin/bash

# Restart triggered by workshop mod being updated

screen -S zomboid -X stuff 'servermsg "The server will restart in 5 minutes for a mod update."^M'
sleep 240
screen -S zomboid -X stuff 'servermsg "The server will restart in 1 minute for a mod update."^M'
screen -S zomboid -X stuff 'save'
sleep 60
screen -S zomboid -X stuff 'quit'
sleep 15
screen -S zomboid -X stuff '/opt/pzserver/start-server.sh -servername servertest-2'
