#! /bin/bash

##################################################################################
#                                                                                #
#  Counter-Strike : Global Offensive Server Launcher                             #
#                                                                                #
#  Author: Cr@zy                                                                 #
#  Contact: http://www.crazyws.fr                                                #
#  Related article: http://goo.gl/HFFGy                                          #
#                                                                                #
#  This program is free software: you can redistribute it and/or modify it       #
#  under the terms of the GNU General Public License as published by the Free    #
#  Software Foundation, either version 3 of the License, or (at your option)     #
#  any later version.                                                            #
#                                                                                #
#  This program is distributed in the hope that it will be useful, but WITHOUT   #
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS #
#  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more         #
#  details.                                                                      #
#                                                                                #
#  You should have received a copy of the GNU General Public License along       #
#  with this program.  If not, see http://www.gnu.org/licenses/.                 #
#                                                                                #
#  Usage: ./csgo {start|stop|status|restart|console|update}                      #
#    - start: start the server                                                   #
#    - stop: stop the server                                                     #
#    - status: display the status of the server (down or up)                     #
#    - restart: restart the server                                               #
#    - console: display the server console where you can enter commands.         #
#     To exit the console without stopping the server, press CTRL + A then D.    #
#    - update: update the server                                                 #
#                                                                                #
##################################################################################

SCREEN_NAME="csgo"
USER="steam"
IP="1.2.3.4"

DIR_STEAMCMD="/var/steamcmd"
DIR_GAME="$DIR_STEAMCMD/games/csgo"
DAEMON_GAME="srcds_run"

LOG_DIR="$DIR_GAME/csgo/logs"
LOG_FILE="$LOG_DIR/update_`date +%Y%m%d`.log"

PARAM_START="-game csgo -console -usercon -secure -nohltv -maxplayers_override 28 +sv_pure 0 +net_public_adr $IP +game_type 0 +game_mode 0 +mapgroup mg_bomb +map de_dust2"
SCRIPT_UPDATE="csgo_update"

# Do not change this path
PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ ! -x `which awk` ]; then echo "ERROR: You need awk for this script (try apt-get install awk)"; exit 1; fi
if [ ! -x `which screen` ]; then echo "ERROR: You need screen for this script (try apt-get install screen)"; exit 1; fi

function start {
  if [ ! -d $DIR_GAME ]; then echo "ERROR: $DIR_GAME is not a directory"; exit 1; fi
  if [ ! -x $DIR_GAME/$DAEMON_GAME ]; then echo "ERROR: $DIR_GAME/$DAEMON_GAME does not exist or is not executable"; exit 1; fi
  if status; then echo "$SCREEN_NAME is already running"; exit 1; fi

  if [ `whoami` = root ];
  then
    su - $USER -c "cd $DIR_GAME ; screen -AmdS $SCREEN_NAME ./$DAEMON_GAME $PARAM_START"
  else
    cd $DIR_GAME ; screen -AmdS $SCREEN_NAME ./$DAEMON_GAME $PARAM_START
  fi
}

function stop {
  if ! status; then echo "$SCREEN_NAME could not be found. Probably not running."; exit 1; fi

  if [ `whoami` = root ];
  then
    tmp=$(su - $USER -c "screen -ls" | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}')
    su - $USER -c "screen -r $tmp -X quit"
  else
    screen -r $(screen -ls | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}') -X quit
  fi
}

function status {
  if [ `whoami` = root ];
  then
    su - $USER -c "screen -ls" | grep [.]$SCREEN_NAME[[:space:]] > /dev/null
  else
    screen -ls | grep [.]$SCREEN_NAME[[:space:]] > /dev/null
  fi
}

function console {
  if ! status; then echo "$SCREEN_NAME could not be found. Probably not running."; exit 1; fi

  if [ `whoami` = root ];
  then
    tmp=$(su - $USER -c "screen -ls" | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}')
    su - $USER -c "screen -r $tmp"
  else
    screen -r $(screen -ls | awk -F . "/\.$SCREEN_NAME\t/ {print $1}" | awk '{print $1}')
  fi
}

function update {
  if [ ! -d $LOG_DIR ]; then mkdir $LOG_DIR; fi
  
  if status;
  then
    stop; echo "Stop $SCREEN_NAME before update...";
	sleep 5; RELAUNCH=1;
  else
    RELAUNCH=0;
  fi
  
  if [ `whoami` = root ];
  then
    su - $USER -c "cd $DIR_STEAMCMD ; STEAMEXE=steamcmd ./steam.sh +runscript $SCRIPT_UPDATE 2>&1 | tee $LOG_FILE";
  else
    cd $DIR_STEAMCMD ; STEAMEXE=steamcmd ./steam.sh +runscript $SCRIPT_UPDATE 2>&1 | tee $LOG_FILE;
  fi
  
  echo "$SCREEN_NAME updated successfully"
  
  if [ $RELAUNCH = 1 ];
  then
	echo "Restart $SCREEN_NAME..."
	start;
	sleep 5;
	echo "$SCREEN_NAME restarted successfully"
  else
    exit 1;
  fi
}

function usage {
  echo "Usage: $0 {start|stop|status|restart|console|update}"
  echo "On console, press CTRL+A then D to stop the screen without stopping the server."
}

case "$1" in

  start)
    echo "Starting $SCREEN_NAME..."
    start
	sleep 5
    echo "$SCREEN_NAME started successfully"
  ;;

  stop)
    echo "Stopping $SCREEN_NAME..."
    stop
	sleep 5
    echo "$SCREEN_NAME stopped successfully"
  ;;
 
  restart)
    echo "Restarting $SCREEN_NAME..."
    status && stop
	sleep 5
    start
	sleep 5
	echo "$SCREEN_NAME restarted successfully"
  ;;

  status)
    if status
    then echo "$SCREEN_NAME is UP" 
    else echo "$SCREEN_NAME is DOWN"
    fi
  ;;
 
  console)
	echo "Open console on $SCREEN_NAME..."
    console
  ;;
  
  update)
    echo "Updating $SCREEN_NAME..."
    update
  ;;

  *)
    usage
	exit 1
  ;;

esac

exit 0




