local wezterm = require('wezterm')
local platform = require('utils.platform')()
local backdrops = require('utils.backdrops')
local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|CTRL'
end

-- Define the action for ⌘/SUPER + W depending on the platform
local cmd_w_action
if platform.is_mac then
   -- On macOS: send Ctrl+W (delete previous word)
   cmd_w_action = act.SendKey({ key = 'w', mods = 'CTRL' })
else
   -- On other platforms: keep the old behaviour of closing the current pane without confirmation
   cmd_w_action = act.CloseCurrentPane({ confirm = false })
end

-- Define actions for ⌘/SUPER + Arrow and ⌘/SUPER + Backspace depending on the platform
local cmd_left_action, cmd_right_action, cmd_backspace_action
if platform.is_mac then
   cmd_left_action = act.SendKey({ key = 'a', mods = 'CTRL' })  -- move to beginning of line
   cmd_right_action = act.SendKey({ key = 'e', mods = 'CTRL' }) -- move to end of line
   cmd_backspace_action = act.SendKey({ key = 'u', mods = 'CTRL' }) -- delete to beginning of line
else
   cmd_left_action = act.SendString '\x1bOH' -- Home
   cmd_right_action = act.SendString '\x1bOF' -- End
   cmd_backspace_action = act.SendString '\x15' -- Unix-line-discard (Ctrl+U)
end

-- stylua: ignore
local keys = {
   -- misc/useful --
   { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   {
      key = 'F5',
      mods = 'NONE',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
   },
   { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
   { key = 'f',   mods = 'CTRL|SHIFT', action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = mod.SUPER,
      action = wezterm.action.QuickSelectArgs({
         label = 'open url',
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),
   },

   -- send Ctrl+D on Cmd+D --
   { key = 'd', mods = mod.SUPER, action = act.SendKey({ key = 'd', mods = 'CTRL' }) },

   -- cursor movement --
   { key = 'LeftArrow',  mods = mod.SUPER,     action = cmd_left_action },
   { key = 'RightArrow', mods = mod.SUPER,     action = cmd_right_action },
   { key = 'Backspace',  mods = mod.SUPER,     action = cmd_backspace_action },

   -- copy/paste --
   { key = 'c',          mods = 'CTRL|SHIFT',  action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = 'CTRL|SHIFT',  action = act.PasteFrom('Clipboard') },
   { key = 'c',          mods = mod.SUPER,     action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = mod.SUPER,     action = act.PasteFrom('Clipboard') },

   -- tabs --
   -- tabs: spawn+close
   { key = 't',          mods = 'CTRL|SHIFT',     action = act.SpawnTab('DefaultDomain') },
   { key = 't',          mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
   { key = 'w',          mods = 'CTRL|SHIFT', action = act.CloseCurrentTab({ confirm = false }) },

   -- tabs: navigation
   { key = '[',          mods = mod.SUPER,     action = act.ActivateTabRelative(-1) },
   { key = 'Tab',          mods = 'CTRL',     action = act.ActivateTabRelative(1) },
   { key = '[',          mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = ']',          mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },
   { key = 'LeftArrow',  mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- window --
   -- spawn windows
   { key = 'n',          mods = 'CTRL|SHIFT',     action = act.SpawnWindow },

   -- background controls --
   {
      key = [[/]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:random(window)
      end),
   },
   {
      key = [[,]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:cycle_back(window)
      end),
   },
   {
      key = [[.]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:cycle_forward(window)
      end),
   },
   {
      key = [[/]],
      mods = mod.SUPER_REV,
      action = act.InputSelector({
         title = 'Select Background',
         choices = backdrops:choices(),
         fuzzy = true,
         fuzzy_description = 'Select Background: ',
         action = wezterm.action_callback(function(window, _pane, idx)
            ---@diagnostic disable-next-line: param-type-mismatch
            backdrops:set_img(window, tonumber(idx))
         end),
      }),
   },

   -- panes --
   -- panes: split panes
   {
      key = 'e',
      mods = mod.SUPER .. '|SHIFT',
      action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
   },
   {
      key = 'r',
      mods = mod.SUPER .. '|SHIFT',
      action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
   },

   -- panes: zoom+close pane
   { key = 'Enter', mods = mod.SUPER,     action = act.TogglePaneZoomState },
   { key = 'w',     mods = mod.SUPER,     action = cmd_w_action },

   -- panes: navigation
   { key = 'k',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Up') },
   { key = 'j',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Down') },
   { key = 'h',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Left') },
   { key = 'l',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Right') },
   {
      key = 'p',
      mods = mod.SUPER_REV,
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },

   -- key-tables --
   -- resizes fonts
   {
      key = 'f',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_font',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- resize panes
   {
      key = 'p',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
}

-- macOS-specific additional key bindings
if platform.is_mac then
   local mac_keys = {
      { key = 'LeftArrow',  mods = 'OPT',        action = act.SendKey({ key = 'b', mods = 'ALT' }) },
      { key = 'RightArrow', mods = 'OPT',        action = act.SendKey({ key = 'f', mods = 'ALT' }) },
      { key = 'LeftArrow',  mods = 'CMD|OPT',    action = act.ActivateTabRelative(-1) },
      { key = 'RightArrow', mods = 'CMD|OPT',    action = act.ActivateTabRelative(1) },
      { key = 'LeftArrow',  mods = 'CMD|SHIFT',  action = act.ActivateTabRelative(-1) },
      { key = 'RightArrow', mods = 'CMD|SHIFT',  action = act.ActivateTabRelative(1) },
   }
   for _, k in ipairs(mac_keys) do
      table.insert(keys, k)
   end
end

-- stylua: ignore
local key_tables = {
   resize_font = {
      { key = 'k',      action = act.IncreaseFontSize },
      { key = 'j',      action = act.DecreaseFontSize },
      { key = 'r',      action = act.ResetFontSize },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
   resize_pane = {
      { key = 'k',      action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'j',      action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'h',      action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'l',      action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   -- Ctrl-click will open the link under the mouse cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
}

return {
   disable_default_key_bindings = true,
   leader = { key = 'Space', mods = mod.SUPER_REV },
   keys = keys,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
