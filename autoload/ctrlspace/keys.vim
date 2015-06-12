let s:config         = ctrlspace#context#Configuration()
let s:modes          = ctrlspace#modes#Modes()
let s:keyNames       = []
let s:keyMap         = {}
let s:characters     = {}
let s:keyEscSequence = 0

function! ctrlspace#keys#KeyNames()
  return s:keyNames
endfunction

function! ctrlspace#keys#CharacterClasses()
  return s:characters
endfunction

function! ctrlspace#keys#KeyMap()
  return s:keyMap
endfunction

function! ctrlspace#keys#MarkKeyEscSequence()
  let s:keyEscSequence = 1
endfunction

function! ctrlspace#keys#Init()
  call s:initKeyNames()
  call s:initKeyMap()
  call ctrlspace#keys#common#Init()
  call s:initCustomMappings()
endfunction

function! s:initCustomMappings()
  for m in ["Search", "Help", "Nop", "Buffer", "File", "Tablist", "Workspace", "Bookmark"]
    if has_key(s:config.KeyMap, m)
      call extend(s:keyMap[m], s:config.KeyMap[m])
    endif
  endfor
endfunction

function! s:initKeyNames()
  let lowercase = "q w e r t y u i o p a s d f g h j k l z x c v b n m"
  let uppercase = toupper(lowercase)

  let controlList = []

  for l in split(lowercase, " ")
    call add(controlList, "C-" . l)
  endfor

  let controls = join(controlList, " ")

  let numbers  = "1 2 3 4 5 6 7 8 9 0"
  let specials = "Space CR BS Tab S-Tab / ? ; : , . < > [ ] { } ( ) ' ` ~ + - _ = ! @ # $ % ^ & * C-f C-b C-u C-d C-h C-w " .
               \ "Bar BSlash MouseDown MouseUp LeftDrag LeftRelease 2-LeftMouse " .
               \ "Down Up Home End Left Right PageUp PageDown " .
               \ 'F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 "'

  if !s:config.UseMouseAndArrowsInTerm || has("gui_running")
    let specials .= " Esc"
  endif

  let specials .= (has("gui_running") || has("win32")) ? " C-Space" : " Nul"

  let keyNames = split(join([lowercase, uppercase, controls, numbers, specials], " "), " ")

  " won't work with leader mappings
  if ctrlspace#keys#IsDefaultKey()
    for i in range(0, len(keyNames) - 1)
      let fullKeyName = (strlen(keyNames[i]) > 1) ? ("<" . keyNames[i] . ">") : keyNames[i]

      if fullKeyName ==# ctrlspace#keys#DefaultKey()
        call remove(keyNames, i)
        break
      endif
    endfor
  endif

  let s:keyNames  = keyNames
  let s:characters.lowercase = split(lowercase, " ")
  let s:characters.uppercase = split(uppercase, " ")
  let s:characters.controls  = split(controls, " ")
  let s:characters.numbers   = split(numbers, " ")
  let s:characters.specials  = split(specials, " ")
endfunction

function! ctrlspace#keys#Undefined(key, termSTab)
  call ctrlspace#ui#Msg("Undefined key '" . a:key . "' for current list.")
endfunction

function! s:initKeyMap()
  let Undefined = function("ctrlspace#keys#Undefined")
  let blankMap  = {}

  for k in s:keyNames
    let blankMap[k] = Undefined
  endfor

  for m in ["Search", "Help", "Nop", "Buffer", "File", "Tablist", "Workspace", "Bookmark"]
    let s:keyMap[m] = copy(blankMap)
  endfor
endfunction

function! ctrlspace#keys#AddMapping(mapName, keys, funcName)
  let keys = []

  for entry in a:keys
    if has_key(s:characters, entry)
      call extend(keys, s:characters[entry])
    else
      call add(keys, entry)
    endif
  endfor

  let FuncRef = function(a:funcName)

  for k in keys
    let s:keyMap[a:mapName][k] = FuncRef
  endfor
endfunction

function! ctrlspace#keys#Keypressed(key)
  let termSTab = s:keyEscSequence && (a:key ==# "Z")
  let s:keyEscSequence = 0


  if s:modes.Help.Enabled
    let mapName = "Help"
  elseif s:modes.Nop.Enabled
    let mapName = "Nop"
  elseif s:modes.Search.Enabled
    let mapName = "Search"
  else
    let mapName = ctrlspace#modes#CurrentListView().Name

    " TODO Think about expanding this to all modes
    if mapName ==# "Workspace"
      call s:modes.Workspace.SetData("LastBrowsed", line("."))
    endif
  endif

  call s:keyMap[mapName][a:key](a:key, termSTab)
endfunction

function! ctrlspace#keys#SetDefaultMapping(key, action)
  let s:defaultKey = a:key
  if !empty(s:defaultKey)
    if s:defaultKey ==? "<C-Space>" && !has("gui_running") && !has("win32")
      let s:defaultKey = "<Nul>"
    endif

    silent! exe 'nnoremap <unique><silent>' . s:defaultKey . ' ' . a:action
  endif
endfunction

function! ctrlspace#keys#IsDefaultKey()
  return exists("s:defaultKey")
endfunction

function! ctrlspace#keys#DefaultKey()
  return s:defaultKey
endfunction
