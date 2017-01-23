if not igg then igg = {} end
if not igg.players then igg.players = {} end
if not igg.items then igg.items = {} end

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.players[event.player_index]
  igg.players[event.player_index] = false
end)

script.on_event(defines.events.on_player_left_game, function(event)
  local player = game.players[event.player_index]
  igg.players[event.player_index] = nil
end)

script.on_event("igg-toggle", function(event)
  local player = game.players[event.player_index]
  if igg.players[event.player_index] then
    igg.close_gui(player)
  else
    local items = {}
    for _,item in pairs(game.item_prototypes) do
      table.insert(items, item.name)
    end
    igg.items = items
    igg.open_gui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.players[event.player_index]
  local element = event.element
  if igg.players[event.player_index] then
    if element.name == "igg_give_button" or element.name == "igg_take_button" then
      local cmd = element.parent.parent
      if cmd.igg_cmd_item.text == "" then
        player.print("Item cannot be blank!")
        return
      elseif cmd.igg_cmd_amount.text == "" then
        player.print("Amount cannot be blank!")
        return
      elseif not tonumber(cmd.igg_cmd_amount.text) then 
        player.print("Amount must be a valid number!")
        return
      elseif tonumber(cmd.igg_cmd_amount.text) <= 0 then
        player.print("Amount must be more than zero!")
        return
      else
        if element.name == "igg_give_button" then
          give(player, cmd.igg_cmd_item.text, tonumber(cmd.igg_cmd_amount.text))
        elseif element.name == "igg_take_button" then
          take(player, cmd.igg_cmd_item.text, tonumber(cmd.igg_cmd_amount.text))
        end
      end
    elseif element.type == "sprite-button" then
      if not (element.name == "") and string.match(element.name, "igg%_match%_") then
        element.parent.parent.parent.parent.igg_cmd_frame.igg_cmd_item.text = string.sub(element.name, 11)
      end
    end
  end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local player = game.players[event.player_index]
  if igg.players[event.player_index] and event.element.name == "igg_cmd_item" then
    local flow = event.element.parent.parent.igg_cmd_flow
    if flow.igg_cmd_suggest then
      flow.igg_cmd_suggest.destroy()
    end
    local text = event.element.text
    if text == "" then return end
    local matches = {}
    for _,item in pairs(igg.items) do
      if string.match(item, text) then
        table.insert(matches, item)
      end
    end
    if #matches > 0 then
      local suggest = flow.add({type = "scroll-pane", name = "igg_cmd_suggest", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto", style = "igg-scroll-pane", direction = "horizontal"})
      local tab = suggest.add({type = "table", name = "igg_cmd_tab", colspan = (13)})
      for _,match in pairs(matches) do
        tab.add(image(match))
      end
    end
  end
end)

function image(itemName)
  local item = game.item_prototypes[itemName]
  local tip = item.localised_name
  return {
    type = "sprite-button",
    name = "igg_match_"..itemName,
    style = "slot_button_style",
    tooltip = tip,
    sprite = "item/"..itemName
  }
end

function igg.open_gui(player)
  if player.gui.center.igg_gui then
    igg.close_gui(player)
  end
  igg.players[player.index] = true
  local ui = player.gui.center.add({type = "frame", name = "igg_gui",direction = "vertical"})
  local cmd_line = ui.add({type = "frame", name = "igg_cmd_frame", direction = "horizontal"})
  cmd_line.add({type = "label", caption = "Item:"})
  cmd_line.add({type = "textfield", name = "igg_cmd_item"})
  cmd_line.add({type = "label", caption = "Amount:"})
  cmd_line.add({type = "textfield", name = "igg_cmd_amount", text = "1"})
  local buttons = cmd_line.add({type = "flow", name = "igg_cmd_buttons", direction = "horizontal"})
  buttons.add({type = "button", name = "igg_take_button", caption = "Remove"})
  buttons.add({type = "button", name = "igg_give_button", caption = "Give"})
  ui.add({type = "flow", name = "igg_cmd_flow", direction = "horizontal"})
end

function igg.close_gui(player)
   igg.players[player.index] = false
   player.gui.center.igg_gui.destroy()
end

function igg.get_items()
  return game.item_prototypes
end

function give(player, i, amount)
  local items = igg.get_items()
  if items[i] then
    local item = {name=i, count = amount}
    if player.can_insert(item) then
      local amount = player.insert(item)
      player.print("Successfully inserted "..amount.." items!")
    else
      player.print("Not enough inventory space")
    end
  else
    player.print("Invalid item!")
  end
end

function take(player, i, amount)
  local items = igg.get_items()
  if items[i] then
    local item = {name=i, count = amount}
    local main = player.get_inventory(defines.inventory.player_main)
    local bar = player.get_inventory(defines.inventory.player_quickbar)
    if main.find_item_stack(i) or bar.find_item_stack(i) then
      local amount = player.remove_item(item)
      player.print("Successfully removed "..amount.." items!")
    else
      player.print("You do not have any of those items to remove!")
    end
  else
    player.print("Invalid item!")
  end
end