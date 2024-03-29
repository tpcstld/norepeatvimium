Commands =
  init: ->
    for command, description of commandDescriptions
      @addCommand(command, description[0], description[1])

  availableCommands: {}
  keyToCommandRegistry: {}

  # Registers a command, making it available to be optionally bound to a key.
  # options:
  #  - background: whether this command needs to be run against the background page.
  #  - passCountToFunction: true if this command should have any digits which were typed prior to the
  #    command passed to it. This is used to implement e.g. "closing of 3 tabs".
  addCommand: (command, description, options) ->
    if command of @availableCommands
      console.log(command, "is already defined! Check commands.coffee for duplicates.")
      return

    options ||= {}
    @availableCommands[command] =
      description: description
      isBackgroundCommand: options.background
      passCountToFunction: options.passCountToFunction
      noRepeat: options.noRepeat
      repeatLimit: options.repeatLimit

  mapKeyToCommand: (key, command) ->
    unless @availableCommands[command]
      console.log(command, "doesn't exist!")
      return

    commandDetails = @availableCommands[command]

    @keyToCommandRegistry[key] =
      command: command
      isBackgroundCommand: commandDetails.isBackgroundCommand
      passCountToFunction: commandDetails.passCountToFunction
      noRepeat: commandDetails.noRepeat
      repeatLimit: commandDetails.repeatLimit

  unmapKey: (key) -> delete @keyToCommandRegistry[key]

  # Lower-case the appropriate portions of named keys.
  #
  # A key name is one of three forms exemplified by <c-a> <left> or <c-f12>
  # (prefixed normal key, named key, or prefixed named key). Internally, for
  # simplicity, we would like prefixes and key names to be lowercase, though
  # humans may prefer other forms <Left> or <C-a>.
  # On the other hand, <c-a> and <c-A> are different named keys - for one of
  # them you have to press "shift" as well.
  normalizeKey: (key) ->
    key.replace(/<[acm]-/ig, (match) -> match.toLowerCase())
       .replace(/<([acm]-)?([a-zA-Z0-9]{2,5})>/g, (match, optionalPrefix, keyName) ->
          "<" + (if optionalPrefix then optionalPrefix else "") + keyName.toLowerCase() + ">")

  parseCustomKeyMappings: (customKeyMappings) ->
    lines = customKeyMappings.split("\n")

    for line in lines
      continue if (line[0] == "\"" || line[0] == "#")
      splitLine = line.split(/\s+/)

      lineCommand = splitLine[0]

      if (lineCommand == "map")
        continue if (splitLine.length != 3)
        key = @normalizeKey(splitLine[1])
        vimiumCommand = splitLine[2]

        continue unless @availableCommands[vimiumCommand]

        console.log("Mapping", key, "to", vimiumCommand)
        @mapKeyToCommand(key, vimiumCommand)
      else if (lineCommand == "unmap")
        continue if (splitLine.length != 2)

        key = @normalizeKey(splitLine[1])
        console.log("Unmapping", key)
        @unmapKey(key)
      else if (lineCommand == "unmapAll")
        @keyToCommandRegistry = {}

  clearKeyMappingsAndSetDefaults: ->
    @keyToCommandRegistry = {}

    for key of defaultKeyMappings
      @mapKeyToCommand(key, defaultKeyMappings[key])

  # An ordered listing of all available commands, grouped by type. This is the order they will
  # be shown in the help page.
  commandGroups:
    pageNavigation:
      ["scrollDown", "scrollUp", "scrollLeft", "scrollRight", "scrollToTop", "scrollToBottom", "scrollToLeft",
      "scrollToRight", "scrollPageDown", "scrollPageUp", "scrollFullPageUp", "scrollFullPageDown", "reload",
      "toggleViewSource", "copyCurrentUrl", "LinkHints.activateModeToCopyLinkUrl",
      "openCopiedUrlInCurrentTab", "openCopiedUrlInNewTab", "goUp", "goToRoot", "enterInsertMode",
      "focusInput", "LinkHints.activateMode", "LinkHints.activateModeToOpenInNewTab",
      "LinkHints.activateModeToOpenInNewForegroundTab", "LinkHints.activateModeWithQueue", "Vomnibar.activate",
      "Vomnibar.activateInNewTab", "Vomnibar.activateTabSelection", "Vomnibar.activateBookmarks",
      "Vomnibar.activateBookmarksInNewTab", "goPrevious", "goNext", "nextFrame", "Marks.activateCreateMode",
      "Marks.activateGotoMode"]
    findCommands: ["enterFindMode", "performFind", "performBackwardsFind"]
    historyNavigation:
      ["goBack", "goForward"]
    tabManipulation:
      ["nextTab", "previousTab", "firstTab", "lastTab", "createTab", "duplicateTab", "removeTab",
      "restoreTab", "moveTabToNewWindow", "togglePinTab", "closeTabsToLeft","closeTabsToRight",
      "closeOtherTabs", "moveTabLeft", "moveTabRight"]
    misc:
      ["showHelp"]

  # Rarely used commands are not shown by default in the help dialog or in the README. The goal is to present
  # a focused, high-signal set of commands to the new and casual user. Only those truly hungry for more power
  # from Vimium will uncover these gems.
  advancedCommands: [
    "scrollToLeft", "scrollToRight", "moveTabToNewWindow",
    "goUp", "goToRoot", "focusInput", "LinkHints.activateModeWithQueue",
    "LinkHints.activateModeToOpenIncognito", "goNext", "goPrevious", "Marks.activateCreateMode",
    "Marks.activateGotoMode", "moveTabLeft", "moveTabRight"]

defaultKeyMappings =
  "?": "showHelp"
  "j": "scrollDown"
  "k": "scrollUp"
  "h": "scrollLeft"
  "l": "scrollRight"
  "gg": "scrollToTop"
  "G": "scrollToBottom"
  "zH": "scrollToLeft"
  "zL": "scrollToRight"
  "<c-e>": "scrollDown"
  "<c-y>": "scrollUp"

  "d": "scrollPageDown"
  "u": "scrollPageUp"
  "r": "reload"
  "gs": "toggleViewSource"

  "i": "enterInsertMode"

  "H": "goBack"
  "L": "goForward"
  "gu": "goUp"
  "gU": "goToRoot"

  "gi": "focusInput"

  "f":     "LinkHints.activateMode"
  "F":     "LinkHints.activateModeToOpenInNewTab"
  "<a-f>": "LinkHints.activateModeWithQueue"

  "/": "enterFindMode"
  "n": "performFind"
  "N": "performBackwardsFind"

  "[[": "goPrevious"
  "]]": "goNext"

  "yy": "copyCurrentUrl"
  "yf": "LinkHints.activateModeToCopyLinkUrl"

  "p": "openCopiedUrlInCurrentTab"
  "P": "openCopiedUrlInNewTab"

  "K": "nextTab"
  "J": "previousTab"
  "gt": "nextTab"
  "gT": "previousTab"
  "<<": "moveTabLeft"
  ">>": "moveTabRight"
  "g0": "firstTab"
  "g$": "lastTab"

  "W": "moveTabToNewWindow"
  "t": "createTab"
  "yt": "duplicateTab"
  "x": "removeTab"
  "X": "restoreTab"

  "<a-p>": "togglePinTab"

  "o": "Vomnibar.activate"
  "O": "Vomnibar.activateInNewTab"

  "T": "Vomnibar.activateTabSelection"

  "b": "Vomnibar.activateBookmarks"
  "B": "Vomnibar.activateBookmarksInNewTab"

  "gf": "nextFrame"

  "m": "Marks.activateCreateMode"
  "`": "Marks.activateGotoMode"


# This is a mapping of: commandIdentifier => [description, options].
commandDescriptions =
  # Navigating the current page
  showHelp: ["Show help", { background: true }]
  scrollDown: ["Scroll down"]
  scrollUp: ["Scroll up"]
  scrollLeft: ["Scroll left"]
  scrollRight: ["Scroll right"]

  scrollToTop: ["Scroll to the top of the page", { noRepeat: true }]
  scrollToBottom: ["Scroll to the bottom of the page", { noRepeat: true }]
  scrollToLeft: ["Scroll all the way to the left", { noRepeat: true }]
  scrollToRight: ["Scroll all the way to the right", { noRepeat: true }]

  scrollPageDown: ["Scroll a page down"]
  scrollPageUp: ["Scroll a page up"]
  scrollFullPageDown: ["Scroll a full page down"]
  scrollFullPageUp: ["Scroll a full page up"]

  reload: ["Reload the page", { noRepeat: true }]
  toggleViewSource: ["View page source", { noRepeat: true }]

  copyCurrentUrl: ["Copy the current URL to the clipboard", { noRepeat: true }]
  'LinkHints.activateModeToCopyLinkUrl': ["Copy a link URL to the clipboard", { noRepeat: true }]
  openCopiedUrlInCurrentTab: ["Open the clipboard's URL in the current tab", { background: true }]
  openCopiedUrlInNewTab: ["Open the clipboard's URL in a new tab", { background: true, repeatLimit: 3 }]

  enterInsertMode: ["Enter insert mode", { noRepeat: true }]

  focusInput: ["Focus the first text box on the page. Cycle between them using tab",
    { passCountToFunction: true }]

  "LinkHints.activateMode": ["Open a link in the current tab", { noRepeat: true }]
  "LinkHints.activateModeToOpenInNewTab": ["Open a link in a new tab", { noRepeat: true }]
  "LinkHints.activateModeToOpenInNewForegroundTab": ["Open a link in a new tab & switch to it", { noRepeat: true }]
  "LinkHints.activateModeWithQueue": ["Open multiple links in a new tab", { noRepeat: true }]
  "LinkHints.activateModeToOpenIncognito": ["Open a link in incognito window", { noRepeat: true }]

  enterFindMode: ["Enter find mode", { noRepeat: true }]
  performFind: ["Cycle forward to the next find match"]
  performBackwardsFind: ["Cycle backward to the previous find match"]

  goPrevious: ["Follow the link labeled previous or <", { noRepeat: true }]
  goNext: ["Follow the link labeled next or >", { noRepeat: true }]

  # Navigating your history
  goBack: ["Go back in history", { passCountToFunction: true }]
  goForward: ["Go forward in history", { passCountToFunction: true }]

  # Navigating the URL hierarchy
  goUp: ["Go up the URL hierarchy", { passCountToFunction: true }]
  goToRoot: ["Go to root of current URL hierarchy", { passCountToFunction: true }]

  # Manipulating tabs
  nextTab: ["Go one tab right", { background: true }]
  previousTab: ["Go one tab left", { background: true }]
  firstTab: ["Go to the first tab", { background: true }]
  lastTab: ["Go to the last tab", { background: true }]

  createTab: ["Create new tab", { background: true, noRepeat: true }]
  duplicateTab: ["Duplicate current tab", { background: true, noRepeat: true }]
  removeTab: ["Close current tab", { background: true, noRepeat: true }]
  restoreTab: ["Restore closed tab", { background: true, noRepeat: true }]

  moveTabToNewWindow: ["Move tab to new window", { background: true }]
  togglePinTab: ["Pin/unpin current tab", { background: true }]

  closeTabsToLeft: ["Close tabs to the left", {background: true, noRepeat: true}]
  closeTabsToRight: ["Close tabs to the right", {background: true, noRepeat: true}]
  closeOtherTabs: ["Close other tabs", {background: true, noRepeat: true}]

  moveTabLeft: ["Move tab to the left", { background: true, passCountToFunction: true }]
  moveTabRight: ["Move tab to the right", { background: true, passCountToFunction: true  }]

  "Vomnibar.activate": ["Open URL, bookmark, or history entry", { noRepeat: true }]
  "Vomnibar.activateInNewTab": ["Open URL, bookmark, history entry, in a new tab", { noRepeat: true }]
  "Vomnibar.activateTabSelection": ["Search through your open tabs", { noRepeat: true }]
  "Vomnibar.activateBookmarks": ["Open a bookmark", { noRepeat: true }]
  "Vomnibar.activateBookmarksInNewTab": ["Open a bookmark in a new tab", { noRepeat: true }]

  nextFrame: ["Cycle forward to the next frame on the page", { background: true, passCountToFunction: true }]

  "Marks.activateCreateMode": ["Create a new mark", { noRepeat: true }]
  "Marks.activateGotoMode": ["Go to a mark", { noRepeat: true }]

Commands.init()

root = exports ? window
root.Commands = Commands
