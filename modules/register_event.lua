--이벤트 등록

local Load = require('modules.load')
local Gui_Event = require('modules.gui_event')
local Tracking = require('modules.tracking')

local pcwrap = function(f)
  return function(e)
    local s, m = pcall(f,e)
    if not s then
      if e.player_index then
        game.players[e.player_index].print('[font=count-font]'..m..'[/font]',{1,0.85,0.7,1})
      end
    end
  end
end

script.on_event(defines.events.on_gui_click, pcwrap(Gui_Event.on_gui_click))
script.on_event(defines.events.on_gui_closed, pcwrap(Gui_Event.on_gui_closed))
script.on_event(defines.events.on_gui_value_changed, pcwrap(Gui_Event.on_gui_value_changed))
script.on_event(defines.events.on_gui_confirmed, pcwrap(Gui_Event.on_gui_confirmed))
script.on_event(defines.events.on_gui_selected_tab_changed, pcwrap(Gui_Event.on_gui_selected_tab_changed))
script.on_event(defines.events.on_gui_checked_state_changed, pcwrap(Gui_Event.on_gui_checked_state_changed))
script.on_event(defines.events.on_gui_text_changed, pcwrap(Gui_Event.on_gui_text_changed))
script.on_event(defines.events.on_gui_selection_state_changed, pcwrap(Gui_Event.on_gui_selection_state_changed))
script.on_event('toggle-main-frame_gvv-mod', Gui_Event['toggle-main-frame_gvv-mod'])
script.on_event(defines.events.on_tick, Tracking.on_tick)

script.on_init(Load.on_init)
script.on_load(Load.on_load)
script.on_configuration_changed(Load.on_configuration_changed)
