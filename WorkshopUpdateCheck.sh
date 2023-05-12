#!/bin/bash

# This script will query the Steam API to find updates for workshop mods present in the server ini. Called using a cron job.

# Set these variables
PATH_TO_SERVER_INI="/home/pzuser/Zomboid/Server"
SERVER_NAME="servertest-2"

echo "Zomboid Server Utility - Workshop Mod Update Check"

# Retrieve the time_updated record from the last time a mod was updated using this script.
# If first time running this script then set epoch time to 0 so script can initialize. The server will restart.
last_time_updated_file="${SERVER_NAME}_ModUpdateRecord"
last_time_updated_path="${PATH_TO_SERVER_INI}/${last_time_updated_file}"

if [[ -f "$last_time_updated_path" ]]; then
	echo "Previous record found."
	last_time_updated_epoch=$(cat ${last_time_updated_path})
	tenMinutesAgo=$(date +%s)
	tenMinutesAgo=${tenMinutesAgo}-600;
	# Delay for recent updates
	if [[ ${last_time_updated_epoch} -gt ${tenMinutesAgo} ]];
	then
		echo "Previous update was less than 10 minutes ago. Canceling script."
		exit 1
	fi
else
	echo "Previous record not found. Initializing file."
	touch $last_time_updated_path
	echo "0" > ${last_time_updated_path}
	last_time_updated_epoch=$(cat ${last_time_updated_path})
fi

echo "Reading workshop IDs."

# Read active workshop mod IDs from server ini
workshopIDs=$(cat ${PATH_TO_SERVER_INI}/${SERVER_NAME}.ini | awk '/^[^#]/ && /WorkshopItems=/' | sed -E 's/WorkshopItems=//g')

# Parse workshop IDs into array
readarray -td ";" workshopIDsArray < <(printf '%s' "$workshopIDs");

# Build Steam API request string
dataquery="itemcount=${#workshopIDsArray[@]}"

for i in "${!workshopIDsArray[@]}"
do
    dataquery="${dataquery}&publishedfileids[$i]=${workshopIDsArray[$i]}"
done

echo "Performing API call."

# Bulk SteamAPI Request
# Parse updated times from response into semicolon delimited string
timesUpdated=$(curl -s -X POST https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/ -d "$dataquery" | grep -Po '"time_updated":[0-9]*' | sed -E 's/"time_updated"://g' | tr '\n' ';')

# Parse update times into array
readarray -td ";" timesUpdatedArray < <(printf '%s' "$timesUpdated");

updated=false

# Compare times to last updated time
for element in "${timesUpdatedArray[@]}"
do
	if [[ ${element} -gt ${last_time_updated_epoch} ]]; 
	then
		# Update latest time
		last_time_updated_epoch=${element}
		echo "${element}" > ${last_time_updated_path}
		updated=true
	fi
done

# Updated Mod Handling

if [[ "$updated" = true ]];
then
	echo "A mod has updated since the last check."
	echo "Beginning restart sequence. 5 minutes to restart."
	# Detach process
	screen -d -m /home/pzuser/Zomboid/Server/Scripts/WorkshopUpdateRestart.sh ${SERVER_NAME}
else
	echo "No mods to update."
fi
