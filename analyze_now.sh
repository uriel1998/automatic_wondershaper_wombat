#!/bin/bash

#requires awk
#requires speedtest (python or perl version)
#
#Python: https://github.com/sivel/speedtest-cli
#Speedtest-cli logs in this manner:
#
#Mon 1 00:01
#Ping: 16.828 ms
#Download: 14.05 Mbit/s
#Upload: 1.02 Mbit/s
#
#Perl: https://metacpan.org/pod/App::SpeedTest
#Perl App::SpeedTest logs in this manner:
#
#$ speedtest -1Qv0
#DL:   40.721 Mbit/s, UL:   30.307 Mbit/s


#TODO: Maybe test with both?
#TODO: Offer to d/l or install both, since it's pip and CPAN?
#TODO: Slight randomization
#TODO: both mode
#TODO: daemonization


# Attempting to get a statistical average
#Mon 1 00:01
#Ping: 16.828 ms
#Download: 14.05 Mbit/s
#Upload: 1.02 Mbit/s


#https://blog.terminal.com/using-daemon-to-daemonize-your-programs/
#setsid myscript.sh >/dev/null 2>&1 < /dev/null &
#http://manpages.ubuntu.com/manpages/xenial/en/man8/start-stop-daemon.8.html

#Finding hour and day of week
# format may be wrong, writing this at work
# using Avgtime to get both day and time



declare -i IsLogged=0
declare Avghour
declare Avgday
declare Avgtime
declare Speedlog


logfile_location() {

	#
	#default location is either .config in $HOME or in $HOME itself
	if [[ "$@" == *"--logfile"* ]]; then
		Speedlog=$(echo "$@" | awk -F "--logfile=" '{print $2}')
	else
		if [ -f "$HOME/Speedlog.log" ]; then
			Speedlog="$HOME/Speedlog.log"
		else
			if [ -f "$HOME/.config/Speedlog.log"]; then
				Speedlog="$HOME/.config/Speedlog.log"
			else	
				>&2 echo "Speedtest log not present; analysis cannot occur."
			fi
		fi
	fi
}

logging() {

	declare local scratch
	declare local speedtest_location

	date +%a\ \%u\ %H:%M | tee -a "$SpeedLog"
	
	# Which speedtest do we have?
	# Checking the shebang; this *should* work....
	speedtest_location=$(which speedtest)
	if [ ! -f "$speedtest_location" ]; then
		speedtest_location=$(which speedtest-cli)
		if [ ! -f "$speedtest_location" ]; then
		>&2 echo "Speedtest CLI not present"
		fi
	fi
	#should read the first line of the file and get the shebang
	read -r scratch<"$speedtest_location"

	case "$scratch" in
		*"python")
			speedtest --simple | tee -a "$SpeedLog"	
			echo " " >> "$SpeedLog"
			;;
		*"perl")
			#awk here is to take the "quick output" from the perl version and change it into the same format.
			speedtest --realquick --one-line | tail -1 |  awk '{print "Download: "$2" Mbit/s\nUpload: "$4" Mbits/s\n"}' | tee -a "$SpeedLog"
			echo " " >> "$SpeedLog"
			;;
		*)
			>&2 echo "Speedtest CLI does not seem to be an identifiable python or perl executable."
			;;
	esac
}

now_variables() {
		Avghour=$(date +\ \%H:)
		Avgday=$(date +%a\ \%u)
		Avgtime=$(date +%a\ \%u\ %H:)
}

match_time() {
		#seeing if there's matches for our time (to the hour), day of week
		IsLogged=$(cat $Speedlog | grep "$1" -c )
}


select_analyze_time() {
	if [ ! -f "$Speedlog" ]; then
		>&2 echo "Speedtest log not present; analysis cannot occur."
	fi
	if [ "$1" =~ "--now" ]; then
		now_variables
		#testing to see which now they're wanting
		case "$1" in
			"--nowhour")
				match_time "$Avghour"
				echo "There are $IsLogged samples for this hour of the day."
				;;
			"--nowday")
				match_time "$Avgday"
				echo "There are $IsLogged samples for this day of the week."
				;;
			"--now")
				match_time "$Avgtime"
				echo "There are $IsLogged samples for this hour and day of week."
				;;
			*)
				"This does not look like the correct argument."
				;;
		esac	
		if [ $IsLogged == 0 ]; then
			echo "Utilizing full file analysis."
		fi
	else
		echo "Utilizing full file analysis."
		IsLogged=0
	fi
}

analyze_speed() {
	if [ $IsLogged == 0 ]; then
		echo "Using full file."
		downloadspeed=$(cat $Speedlog | grep Download: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
		uploadspeed=$(cat $Speedlog | grep Upload: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
	else
		#not sure if A needs to be three or four
		downloadspeed=$(cat $Speedlog | grep "$Avgtime" -A 3 | grep Download: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
		uploadspeed=$(cat $Speedlog | grep "$Avgtime" -A 3 | grep Upload: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
	fi
}

shape_traffic() {
	#Wherein our hero actually applies the values obtained.

}


show_help() {
	#Wherein our hero tells the user what's what.
	echo "This program is designed to record and analyze net speed measurements in order to shape traffic to statistical averages of bandwidth."
	echo "While it may not mazimize your speed, it should make sure your throughput is always steady and stable."
	echo "To use as a logger:"
	echo "analyze_netspeed [ --logger | --daemon ] \n"
	echo "--logger - begins logging engine."
	echo "--daemon - use as the second variable to force the logging process into the background \n"
	echo "--both - use after logger or daemon to utilize both perl and python variants of cli speedtest."
	echo "To analyze and apply the data obtained after logging, the usage is:"
	echo "analyze_netspeed [ --samples |--analyze | --shape ] [ --now | --nowhour | --nowday ] \n"
	echo "--analyze - analyzes $Speedlog for the full average bandwidth."
	echo "--shape - analyzes $Speedlog and applies shaping according to analysis."
	echo "--samples - analyzes $Speedlog for the number of samples collected in total and for the current time."
	echo "--nowhour - use as the second variable to perform analysis/shaping for the current hour, with a fallback to the full average"
	echo "--nowday - use as the second variable to perform analysis/shaping for the current day of week, with a fallback to the full average"
	echo "--now - use as the second variable to perform analysis/shaping for the current hour AND day of week, with a fallback to the full average"
	echo "\nTo specify log location (the default location is $Speedlog), the usage is"
	echo "--logfile=/path/to/logfile"
	echo "Specifying the logfile location MUST be the last argument passed."
}

main() {

	logfile_location "$@"

	case "$1" in
		# No command-line parameters,
		"") 
			show_help
			exit 2
		;;
		"--logger")
			logger
			# we need to add the loop and a number of times to test and such here.
		;;
		"--daemon")
		;;
		"--samples")
			now_variables
			select_analyze_time "$2"
			IsLogged=$(cat $Speedlog | grep "Download:" -c )
			echo "There are $IsLogged samples total."
		;;
		"--analyze")
			select_analyze_time "$2"
			analyze_speed
		;;
		"--shape")
			select_analyze_time "$2"
			analyze_speed
			shape_traffic			
		*)
			show_help
		;;
	esac
	exit 0
}