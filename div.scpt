-- check if active application is in full screen mode
on isItFullScreen()
  tell application "System Events"
    set activeApp to item 1 of (get name of processes whose frontmost is true)
    tell process activeApp
      get value of attribute "AXFullScreen" of window 1
    end tell
  end tell
  return result as boolean
end isItFullScreen

on getActiveSceenIndex(divObjC)
  set screensCount to divObjC's getScreensCount()
  set screensSizes to divObjC's getScreensSizes()
  set screensOrigins to divObjC's getScreensOrigins()

  tell application "System Events"
    set activeApp to name of first application process whose frontmost is true
    tell process activeApp

      if subrole of window 1 is "AXUnknown" then
        set activeWindow to 2
      else
        set activeWindow to 1
      end if

      set positionOfCurrentApp to position of window activeWindow
      set sizeOfCurrentApp to size of window activeWindow
      set centerOfCurrentApp to (item 1 of positionOfCurrentApp) + (item 1 of sizeOfCurrentApp / 2)

      set activeScreenIndex to 1
      set distanceFromDisplayCenter to 9999

      repeat with screenIndex from 1 to screensCount
        set currentScreenXorigin to item 1 of item screenIndex of screensOrigins
        set currentScreenXsize to item 1 of item screenIndex of screensSizes
        set currentScreenCenter to currentScreenXorigin + (currentScreenXsize / 2)
        set currentScreenCenterDistanceToAppCenter to centerOfCurrentApp - currentScreenCenter
        if currentScreenCenterDistanceToAppCenter < 0 then set currentScreenCenterDistanceToAppCenter to -currentScreenCenterDistanceToAppCenter

        if currentScreenCenterDistanceToAppCenter < distanceFromDisplayCenter
          set activeScreenIndex to screenIndex
          set distanceFromDisplayCenter to currentScreenCenterDistanceToAppCenter
        end if
      end repeat

    end tell
  end tell

  return activeScreenIndex
end getActiveSceenIndex

-- return active screens size
on screenSize(divObjC)
  set screensCount to divObjC's getScreensCount()
  set screensSizes to divObjC's getScreensSizes()

  if screensCount is 1
    set _width to item 1 of item 1 of screensSizes
    set _height to item 2 of item 1 of screensSizes
  else
    set activeSceenIndex to getActiveSceenIndex(divObjC)
    set _width to item 1 of item activeSceenIndex of screensSizes
    set _height to item 2 of item activeSceenIndex of screensSizes
  end if

  return {_width, _height}
end screenSize

-- convert arguments to list
on converttoList(delimiter, input)
  local delimiter, input, ASTID
  set ASTID to AppleScript's text item delimiters
  try
    set AppleScript's text item delimiters to delimiter
    set input to text items of input
    set AppleScript's text item delimiters to ASTID
    return input --> list
  on error eMsg number eNum
    set AppleScript's text item delimiters to ASTID
    error "Can't convert: " & eMsg number eNum
  end try
end converttoList

-- resize app window
on resizeApp(positionX, positionY, sizeX, sizeY)
  tell application "System Events"
    set activeApp to name of first application process whose frontmost is true
    tell process activeApp

        if subrole of window 1 is "AXUnknown" then
          set activeWindow to 2
        else
          set activeWindow to 1
        end if

        set position of window activeWindow to {positionX, positionY}
        set size of window activeWindow to {sizeX, sizeY}

    end tell
  end tell
end resizeApp

-- display notification
on displayNotification(_notification, _subtitle)
  display notification _notification with title "Div" subtitle _subtitle sound name "Basso"
end displayNotification

-- on script invocation read the passed argumens and assign to userQuery
on run userQuery
  -- Load Objective-C script
  tell application "Finder"
    set myPath to container of (path to me) as text
  end tell
  set divObjC to load script file (myPath & "divObjC.scptd")

  -- set some variables
  set screenBounds to screenSize(divObjC)
  set args to converttoList(" ", userQuery)
  set argsSize to count of args
  set isCurrentAppInFullScreenMode to isItFullScreen()

  -- set screensCount to divObjC's getScreensCount()
  -- set screensOrigins to divObjC's getScreensOrigins()
  -- set screensSizes to divObjC's getScreensSizes()
  -- log screensCount
  -- log screensOrigins
  -- log screensSizes
  -- based on this one i can check if we deal with multiple monitos
  -- if not, carry one
  -- if yes, i can get the origin and possitin of a screen needed to count agains

    -- set pTemp to position of window activeWindow
    -- set sTemp to size of window activeWindow
    -- log pTemp
    -- log sTemp
    -- based on this info i can find where the item is
    -- and override screenBounds

  -- warn user that the Div doesn't work in full screen mode
  if isCurrentAppInFullScreenMode is true then
    set _notification to "Div doesn't work in full screen mode!"
    set _subtitle to "Sorry dude :-("
    displayNotification(_notification, _subtitle)
    return
  end if

  -- if user provided 4 arguments, resize to custom bounds
  if argsSize is 4 then
    set positionX to (item 1 of args / 100) * item 1 of screenBounds
    set positionY to (item 2 of args / 100) * item 2 of screenBounds
    set sizeX to ((item 3 of args / 100) - (item 1 of args / 100)) * item 1 of screenBounds
    set sizeY to ((item 4 of args / 100) - (item 2 of args / 100)) * item 2 of screenBounds
    resizeApp(positionX, positionY, sizeX, sizeY)

  -- if user provided 2 arguments, resize to absolute size on the center of a window
  else if argsSize is 2 then

    -- if monitor is not big enough to resize
    if item 1 of args as number > item 1 of screenBounds as number or item 2 of args as number > item 2 of screenBounds as number then
      set _notification to "Buy a bigger one dude"

      set _subtitle to "Screen not big enough :-("
      displayNotification(_notification, _subtitle)

    -- otherwise resize to desired size
    else
      set positionX to (item 1 of screenBounds - item 1 of args) / 2
      set positionY to (item 2 of screenBounds - item 2 of args) / 2
      set sizeX to item 1 of args
      set sizeY to item 2 of args
      resizeApp(positionX, positionY, sizeX, sizeY)
    end if

  -- Otherwise remmind your user how many arguments is required
  else
    set _notification to "Two or four arguments (space separated) only!"
    set _subtitle to "Sorry dude :-("
    displayNotification(_notification, _subtitle)
  end if

end run
