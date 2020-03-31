#!/bin/bash
###############################################################################
# Name: Slack Install
# Created by: Mann Consulting (support@mann.com)
# Version : March 23 2020
# Based on work by: Shaquir Tannis
# Summary: 	Downloads the latest version of Slack from slack.com
#
# Priority: After
#
# Parameters:
#		 1-3 are reserved by JAMF's Casper Suite.
#		 4: Close Slack (1 closes it, leave blank to stay open. Staying open will delay upgrades)
#		 5: Argument 5 details
#		 6: Argument 6 details
#		 7: Argument 7 details
#		 8: Argument 8 details
#		 9: Argument 9 details
#		10: Argument 10 details
#		11: Argument 11 details
#	Exit Codes:
# 		0: Successful!
#		1: Generic Error, undefined
#
# Usage:
#	First policy: Run as part of a policy at logout or checkin, as desired.
#               For speed, policy should be scoped to machines with pending
#               updates, rather than all updates.
#
# Do Note:	This script is part of Mann Consulting's Jamf Pro Maintenance subscription and is only
# 			authorized for use for current subscribers.  If you'd like updates or support
#			sign up at https://mann.com/jamf or email support@mann.com for more details
###############################################################################

#To close Slack, Input "1" in Parameter 4
closeSlack="$4"

#Find latest Slack version / Pulls Version from Slack for Mac download page
currentSlackVersion=$(/usr/bin/curl -sL 'https://slack.com/release-notes/mac/rss' | grep -o "Slack-[0-9]\.[0-9]\.[0-9]"  | cut -c 7-11 | head -n 1)
LOGO="/Applications/Slack.app/Contents/Resources/electron.icns"

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

################################ Error Checking #################################


# The title of the message..
PROMPT_TITLE="Slack Update Required"

# The body of the message that will be displayed before prompting the user for
# their password. All message strings below can be multiple lines.
PROMPT_MESSAGE="Your version of Slack is out of date. Click the Update Now button below, to quit Slack and install the latest Version."


################################ Install Function #################################

installSlack(){
	slackDownloadUrl=$(curl "https://slack.com/ssb/download-osx" -s -L -I -o /dev/null -w '%{url_effective}')
	dmgName=$(printf "%s" "${slackDownloadUrl[@]}" | sed 's@.*/@@')
	slackDmgPath="/tmp/$dmgName"

#Begin Download

#Downloads latest version of Slack
curl -L -o "$slackDmgPath" "$slackDownloadUrl"

#Mounts the .dmg
hdiutil attach -nobrowse $slackDmgPath

# Remove the existing Application
rm -rf /Applications/Slack.app

#Copy the update app into applications folder
ditto -rsrc /Volumes/Slack*/Slack.app /Applications/Slack.app


#Unmount and eject dmg
mountName=$(diskutil list | grep Slack | awk '{ print $3 }')
umount -f /Volumes/Slack*/
diskutil eject $mountName

#Clean up /tmp download
rm -rf "$slackDmgPath"
echo "Slack has been installed"
open /Applications/Slack.app
}

################################ Check if Slack is Open #################################
slackOpen(){

osascript -e "do shell script \"

  if (ps aux | grep Slack | grep -v grep > /dev/null)
  then
      echo "RUNNING"
  else
      echo "NOT_RUNNING"
  fi
\""
}
################################ MAIN PROCESS #################################
echo "Slack Version is currently $currentSlackVersion"
running=$(slackOpen)
echo $running
#Ask User if Slack can be updated
	#statement


if [[ $running = NOT_RUNNING ]]; then
	installSlack
	echo "it reaches here"
else
	user_approve=$("$jamfHelper" -windowType utility -icon $LOGO -title $PROMPT_TITLE -description "$PROMPT_MESSAGE" -button1 "Update Now" -button2 "Update Later" -defaultButton 1)
	echo $user_approve
	if [[ $user_approve = 0 ]]; then
		killall Slack
		echo "slack was closed"
		installSlack
		open Slack.app
	else
		echo "user deferred"
		exit
	fi
fi

	#statements

