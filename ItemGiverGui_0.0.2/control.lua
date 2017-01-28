if not igg then igg = {} end
if not igg.items then igg.items = {} end

script.on_event("igg-toggle", function(event)
  local player = game.players[event.player_index]
  if igg.gui_is_open(player) then
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
      player.gui.center.igg_gui.igg_cmd_frame.igg_line1.igg_cmd_item.text = string.sub(element.name, 11)
    end
  elseif element.name == "igg_inv" then
    local flow = player.gui.center.igg_gui.igg_cmd_flow 
    if flow.igg_cmd_suggest then
      flow.igg_cmd_suggest.destroy()
    end
    if element.state == true then
      local matches = get_inventory(player)
      if #matches > 0 then
        local suggest = flow.add({type = "scroll-pane", name = "igg_cmd_suggest", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto", style = "igg-scroll-pane", direction = "horizontal"})
        local tab = suggest.add({type = "table", name = "igg_cmd_tab", colspan = (13)})
        for _,match in pairs(matches) do
          tab.add(image(match))
        end
      end
    else
      if flow.igg_cmd_suggest then
        flow.igg_cmd_suggest.destroy()
      end
    end
  end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local player = game.players[event.player_index]
  if event.element.name == "igg_cmd_item" then
    local flow = player.gui.center.igg_gui.igg_cmd_flow 
    if flow.igg_cmd_suggest then
      flow.igg_cmd_suggest.destroy()
    end
    local text = event.element.text
    if text == "" then return end
    text = string.gsub(text, "%p", "%%%0")
    local matches = {}
    local items = igg.items
    if is_checked(player) == true then
      local temp = {}
      for _,i in pairs(get_inventory(player)) do
        table.insert(temp, i)
      end
      items = temp
    end
    for _,item in pairs(items) do
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

function is_checked(player)
  return player.gui.center.igg_gui.igg_cmd_frame.igg_line2.igg_inv.state
end

function get_inventory(player)
  local items = {}
  local main = player.get_inventory(defines.inventory.player_main).get_contents()
  local bar = player.get_inventory(defines.inventory.player_quickbar).get_contents()
  for k,v in pairs(bar) do
    if main[k] then
      main[k] = main[k] + v
    else
      main[k] = v
    end
  end
  for k,v in pairs(main) do
    table.insert(items, k)
  end
  return items
end

function image(itemName, amount)
  if not amount then amount = 0 end
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
  if igg.gui_is_open(player) then
    igg.close_gui(player)
  end
  
  local ui = player.gui.center.add({type = "frame", name = "igg_gui",direction = "vertical"})

  local cmd_line = ui.add({type = "frame", name = "igg_cmd_frame", direction = "vertical"})
  
  local flow1 = cmd_line.add({type = "flow", name = "igg_line1", direction = "horizontal"})
  
  flow1.add({type = "label", caption = "Item:"})
  flow1.add({type = "textfield", name = "igg_cmd_item"})
  flow1.add({type = "label", caption = "Amount:"})
  flow1.add({type = "textfield", name = "igg_cmd_amount", text = "1"})
  
  local flow2 = cmd_line.add({type = "flow", name = "igg_line2", direction = "horizontal"})
  
  flow2.add({type = "checkbox", name = "igg_inv", state = false})
  flow2.add({type = "label", caption = "Show inventory items"})
  
  local buttons = flow1.add({type = "flow", name = "igg_cmd_buttons", direction = "horizontal"})
  
  buttons.add({type = "button", name = "igg_take_button", caption = "Remove"})
  buttons.add({type = "button", name = "igg_give_button", caption = "Give"})
  
  ui.add({type = "flow", name = "igg_cmd_flow", direction = "horizontal"})
end

function igg.close_gui(player)
   player.gui.center.igg_gui.destroy()
end

function igg.gui_is_open(player)
  if player.gui.center.igg_gui then
    return true
  else
    return false
  end
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