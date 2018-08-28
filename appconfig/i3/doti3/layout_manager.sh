#!/bin/bash

LAYOUT_PATH=~/.layouts
mkdir -p $LAYOUT_PATH > /dev/null 2>&1

if [ -z $1 ]; then

  ACTION=$(echo "LOAD LAYOUT
SAVE LAYOUT
DELETE LAYOUT" | rofi -i -dmenu -no-custom -p "Select action")

  if [ -z "$ACTION" ]; then
    exit
  fi

  # get me the nemes based on the existing file names in the home
  LAYOUT_NAMES=$(ls -a $LAYOUT_PATH | grep "layout.*json" | sed -nr 's/layout-(.*)\.json/\1/p' | sed 's/\s/\n/g')
  LAYOUT_NAME=$(echo "$LAYOUT_NAMES" | rofi -dmenu -p "Select layout")
  LAYOUT_NAME=${LAYOUT_NAME^^}

else

  ACTION="LOAD LAYOUT"
  LAYOUT_NAME="${1^^}"

fi

if [ -z "$LAYOUT_NAME" ]; then
  exit
fi

LAYOUT_FILE=$LAYOUT_PATH/layout-"$LAYOUT_NAME".json
CURRENT_WORKSPACE_ID=$(~/.i3/get_current_workspace.sh)

if [[ "$ACTION" = "LOAD LAYOUT" ]]; then

  # updating the workspace to the new layout is tricky
  # normally it does not influence existing windows
  # For it to apply to existing windows, we need to
  # first remove them from the workspace

  WINDOWS=$(~/.i3/workspace_list_windows.sh)

  for window in $WINDOWS; do

    HAS_PID=$(xdotool getwindowpid $window 2>&1 | grep "pid" | wc -l)

    if [ ! $HAS_PID -eq 0 ]; then
      echo "$window does not have a process"
    else
      echo sending $window to back
      xdotool windowunmap $window
    fi

  done

  echo "killing the reamins"

  # delete all empty layout windows from the workspace
  i3-msg "focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, focus parent, kill"

  # then we can apply to chosen layout
  i3-msg "append_layout $LAYOUT_FILE"

  # and then we can reintroduce the windows back to the workspace

  for window in $WINDOWS; do
    HAS_PID=$(xdotool getwindowpid $window 2>&1 | grep "pid" | wc -l)

    if [ ! $HAS_PID -eq 0 ]; then
      echo "$window does not have a process"
    else
      xdotool windowmap $window
    fi
  done

fi

if [[ "$ACTION" = "SAVE LAYOUT" ]]; then

  ACTION=$(echo "DEFAULT (INSTANCE)
SPECIFIC (CHOOSE)
MATCH ANY" | rofi -i -dmenu -p "How to identify windows? (xprop style)")


  if [[ "$ACTION" = "DEFAULT (INSTANCE)" ]]; then
    CRITERION="default"
  elif [[ "$ACTION" = "SPECIFIC (CHOOSE)" ]]; then
    CRITERION="specific"
  elif [[ "$ACTION" = "MATCH ANY" ]]; then
    CRITERION="any"
  fi

  ALL_WS_FILE=$LAYOUT_PATH/all-layouts.json

  CURRENT_MONITOR=$(xrandr | grep -w connected | awk '{print $1}')

  # get the i3-tree for all workspaces for the current monitor
  i3-save-tree --output "$CURRENT_MONITOR" > "$ALL_WS_FILE" 2>&1

  # get the i3-tree for the current workspace
  i3-save-tree --workspace "$CURRENT_WORKSPACE_ID" > "$LAYOUT_FILE" 2>&1

  # back the output file.. we are gonna modify it and alter we will need it back
  BACKUP_FILE=$LAYOUT_PATH/.layout_backup.txt
  cp $LAYOUT_FILE $BACKUP_FILE

  # get me vim, we will be using it alot to postprocess the generated json files
  if [ -x "$(whereis nvim | awk '{print $2}')" ]; then
    VIM_BIN="$(whereis nvim | awk '{print $2}')"
    HEADLESS="--headless"
  elif [ -x "$(whereis vim | awk '{print $2}')" ]; then
    VIM_BIN="$(whereis vim | awk '{print $2}')"
    HEADLESS=""
  fi

  # the allaround task is to produce a single json file with the description
  # of the current layout on the focused workspace. However, the
  #                   i3-save-tree --workspace
  # command only outputs the inner containers, without wrapping them into the
  # root container of the workspace, which leads to loosing the information
  # about the initial split .. vertical? or horizontal?...
  # We can solve it by asking for a tree, which contains all workspaces,
  # including the root splits and borrowing the root split info from there.
  # I do it by locating the right place in the all-tree by mathing the
  # workspace tree and then extracting the split part and adding it back
  # to the workspace json.

  # first we need to do some preprocessing, before we can find, where in the
  # all-tree file we can find the workspace part.

  # remove comments
  $VIM_BIN $HEADLESS -nEs -c '%g/\/\//norm dd' -c "wqa" -- "$LAYOUT_FILE"
  $VIM_BIN $HEADLESS -nEs -c '%g/\/\//norm dd' -c "wqa" -- "$ALL_WS_FILE"

  # remove indents
  $VIM_BIN $HEADLESS -nEs -c '%g/^/norm 0d^' -c "wqa" -- "$LAYOUT_FILE"
  $VIM_BIN $HEADLESS -nEs -c '%g/^/norm 0d^' -c "wqa" -- "$ALL_WS_FILE"

  # remove commas
  $VIM_BIN $HEADLESS -nEs -c '%s/^},$/}/g' -c "wqa" -- "$LAYOUT_FILE"
  $VIM_BIN $HEADLESS -nEs -c '%s/^},$/}/g' -c "wqa" -- "$ALL_WS_FILE"

  # remove empty lines in the the workspace file
  $VIM_BIN $HEADLESS -nEs -c '%g/^$/norm dd' -c "wqa" -- "$LAYOUT_FILE"

  # now I will try to find the part in the big file which containts the
  # small file. I have not found a suitable solution using off-the-shelf
  # tools, so custom bash it is...

  MATCH=0
  PATTERN_LINES=`cat $LAYOUT_FILE | wc -l` # get me the number of lines in the small file
  SOURCE_LINES=`cat $ALL_WS_FILE | wc -l` # get me the number of lines in the big file
  echo "pattern lines: $PATTERN_LINES"

  N_ITER=$(expr $SOURCE_LINES - $PATTERN_LINES)
  readarray pattern < $LAYOUT_FILE

  MATCH_LINE=0
  for (( a=1 ; $a-$N_ITER ; a=$a+1 )); do

    CURR_LINE=0
    MATCHED_LINES=0
    while read -r line1; do

      PATTERN_LINE=$(echo ${pattern[$CURR_LINE]} | tr -d '\n')

      if [[ "$line1" == "$PATTERN_LINE" ]]; then
        MATCHED_LINES=$(expr $MATCHED_LINES + 1)
      else
        break
      fi

      CURR_LINE=$(expr $CURR_LINE + 1)
    done <<< $(cat "$ALL_WS_FILE" | tail -n +"$a")

    if [[ "$MATCHED_LINES" == "$PATTERN_LINES" ]];
    then
      echo "matched on line $a"
      MATCH_LINE="$a"
      break
    fi
  done

  # lets extract the key part, containing the block with the root split

  # load old workspace file (we destroyed the old one, remember?)
  mv $BACKUP_FILE $LAYOUT_FILE

  # delete the part below and above the block
  $VIM_BIN $HEADLESS -nEs -c "normal ${MATCH_LINE}ggdGG{kdgg" -c "wqa" -- "$ALL_WS_FILE"
  # rename the "workspace to "con" (container)
  $VIM_BIN $HEADLESS -nEs -c '%g/type/norm ^Wlciwcon' -c "wqa" -- "$ALL_WS_FILE"
  # change the fullscrean to 0
  $VIM_BIN $HEADLESS -nEs -c '%g/fullscreen/norm ^Wr0' -c "wqa" -- "$ALL_WS_FILE"

  # extract the needed part of the file and add it to the workspace file
  # this part is mostly according to the i3 manual, except we actually put there
  # the information about the split type
  cat $ALL_WS_FILE | cat - $LAYOUT_FILE > /tmp/tmp.txt && mv /tmp/tmp.txt $LAYOUT_FILE
  # add closing bracked at the end
  $VIM_BIN $HEADLESS -nEs -c "normal Go]}" -c "wqa" -- "$LAYOUT_FILE"

  # now we have to do some postprocessing on it, all is even advices on the official website
  # https://i3wm.org/docs/layout-saving.html

  # uncomment the instance swallow rule
  if [[ "$CRITERION" = "default" ]]; then
    echo default
    $VIM_BIN $HEADLESS -nEs -c "%g/instance/norm ^dW" -c "wqa" -- "$LAYOUT_FILE"
  elif [[ "$CRITERION" = "any" ]]; then
    echo any
    $VIM_BIN $HEADLESS -nEs -c '%g/instance/norm ^dW3f"di"' -c "wqa" -- "$LAYOUT_FILE"
  elif [[ "$CRITERION" = "specific" ]]; then

    LAST_LINE=1

    while true; do

      LINE_NUM=$(cat $LAYOUT_FILE | tail -n +$LAST_LINE | grep '// "class' -n | awk '{print $1}')
      HAS_INSTANCE=$(echo $LINE_NUM | wc -l)

      if [ ! -z "$LINE_NUM" ]; then

        LINE_NUM=$(echo $LINE_NUM | awk '{print $1}')
        LINE_NUM=${LINE_NUM%:}
        LINE_NUM=$(expr $LINE_NUM - 1)
        LINE_NUM=$(expr $LINE_NUM + $LAST_LINE )

        NAME=$(cat $LAYOUT_FILE | sed -n "$(expr ${LINE_NUM} - 4)p" | awk '{$1="";print $0}')

        SELECTED_OPTION=$(cat -n $LAYOUT_FILE | sed -n "${LINE_NUM},$(expr $LINE_NUM + 2)p" | awk '{$2="";print $0}' | rofi -i -dmenu -no-custom -p "Choose the matching method for${NAME%,}" | awk '{print $1}')

        # when user does not select, choose "instance" (class+1)
        if [ -z "$SELECTED_OPTION" ]; then
          SELECTED_OPTION=$(expr ${LINE_NUM} + 1)
        fi

        $VIM_BIN $HEADLESS -nEs -c "norm ${SELECTED_OPTION}gg^dW" -c "wqa" -- "$LAYOUT_FILE"

        LAST_LINE=$( expr $SELECTED_OPTION)

      else
        break
      fi

    done
  fi

  # uncomment the transient_for
  $VIM_BIN $HEADLESS -nEs -c '%g/transient_for/norm ^dW' -c "wqa" -- "$LAYOUT_FILE"

  # delete all comments
  $VIM_BIN $HEADLESS -nEs -c '%g/\/\//norm dd' -c "wqa" -- "$LAYOUT_FILE"
  # add a missing comma to the last element of array we just deleted
  $VIM_BIN $HEADLESS -nEs -c '%g/swallows/norm j^%k:s/,$//g' -c "wqa" -- "$LAYOUT_FILE"
  # delete all empty lines
  $VIM_BIN $HEADLESS -nEs -c '%g/^$/norm dd' -c "wqa" -- "$LAYOUT_FILE"
  # add missing commas between the newly created inner parts of the root element
  $VIM_BIN $HEADLESS -nEs -c '%s/}\n{/},{/g' -c "wqa" -- "$LAYOUT_FILE"
  # autoformat the file
  $VIM_BIN $HEADLESS -nEs -c 'normal gg=G' -c "wqa" -- "$LAYOUT_FILE"

  notify-send -u low -t 2000 "Layout saved" -h string:x-canonical-private-synchronous:anything

fi

if [[ "$ACTION" = "DELETE LAYOUT" ]]; then

  rm "$LAYOUT_FILE"

fi
