if not igg then igg = {} end
if not igg.items then igg.items = {} end

function try_init()
  if #igg.items > 0 and igg.loaded then return end
  local items = {}
  for _,item in pairs(game.item_prototypes) do
      table.insert(igg.items, item.name)
  end
  igg.loaded = true
end

script.on_event("igg-toggle", function(event)
  try_init()
  local player = game.players[event.player_index]
  if igg.gui_is_open(player) then
    igg.close_gui(player)
  else
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
      igg.update_gui(player, cmd.igg_cmd_item.text, cmd.igg_cmd_amount.text)
    end
  elseif element.type == "sprite-button" then
    if not (element.name == "") and string.match(element.name, "igg%_match%_") then
      igg:get_gui(player.gui.center, "igg_cmd_item").text = string.sub(element.name, 11)
      igg.update_gui(player)
    end
  end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local player = game.players[event.player_index]
  if event.element.name == "igg_cmd_item" then
    local text = event.element.text
    local amount = event.element.parent.igg_cmd_amount.text
    igg.update_gui(player, text, amount)
  elseif event.element.name == "igg_cmd_amount" then
    local text = event.element.text
    local item = event.element.parent.igg_cmd_item.text
    igg.update_gui(player, item, text)
  end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
  local player = game.players[event.player_index]
  local name = event.element.name 
  if (name == "igg_inv")
  or (name == "igg_filter")
  or (name == "igg_sort")
  or (name == "igg_hidden") then
    igg.update_gui(player)
  end
end)

script.on_event(defines.events.on_player_quickbar_inventory_changed, function(event)
  local player = game.players[event.player_index]
  if player.gui.center.igg_gui then
    igg.update_gui(player)
  end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
  local player = game.players[event.player_index]
  if event.element.name == "igg_list" then
    igg.update_gui(player)
  end
end)

function show_inventory(player)
  return igg:get_gui(player.gui.center, "igg_inv").state
end

function show_hidden(player)
  return igg:get_gui(player.gui.center, "igg_hidden").state
end

function filter(player)
  return igg:get_gui(player.gui.center, "igg_filter").state
end

function sort(player)
  return igg:get_gui(player.gui.center, "igg_sort").state
end

function list(player)
  return igg:get_gui(player.gui.center, "igg_list").selected_index
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
    table.insert(items, {name = k, amount = v})
  end
  return items
end

function image(itemName, amount)
  if not amount then amount = 0 end
  local item = game.item_prototypes[itemName]
  local tip = {"igg.item-name", item.localised_name, amount}
  return {
    type = "sprite-button",
    name = "igg_match_"..itemName,
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
  local types = {
    {"igg.all"},
    {"igg.ammo"},
    {"igg.armor"},
    {"igg.belt"},
    {"igg.capsule"},
    {"igg.fuel"},
    {"igg.gun"},
    {"igg.module"},
    {"igg.tool"}
  }
  flow2.add({type = "checkbox", name = "igg_inv", caption = "Inventory", state = false})
  flow2.add({type = "checkbox", name = "igg_hidden", caption = "Show Hidden",state = false})
  flow2.add({type = "checkbox", name = "igg_filter", caption = "Filter",state = true})
  flow2.add({type = "checkbox", name = "igg_sort", caption = "Sort",state = false})
  flow2.add({type = "label", caption = "Item Type:"})
  flow2.add({type = "drop-down", name = "igg_list", items = types, selected_index = 1})
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

function igg:get_gui(gui, name)
  if not self.result then self.result = {} end
  if not gui then return end
  for k,v in pairs(gui.children_names) do
    if gui and gui[v] then
      if gui[v].name == name then
        self.result = gui[v]
        break
      end
      self.result = self:get_gui(gui[v], name)
    end
  end
  return self.result
end

function isListed(list, item)
  if (list == 1) then
    return true
  elseif (list == 2) and (item.type == "ammo") then
    return true
  elseif (list == 3) and (item.type == "armor") then
    return true
  elseif (list == 4) and (item.place_result ~= nil) then
    if (item.place_result.belt_speed ~= nil) then
      return true
    else
      return false
    end
  elseif (list == 5) and (item.type == "capsule") then
    return true
  elseif (list == 6) and (item.fuel_category ~= nil) then
    return true
  elseif (list == 7) and (item.type == "gun") then
    return true
  elseif (list == 8) and (item.type == "module") then
    return true
  elseif (list == 9) and ((item.type == "mining-tool") or (item.type == "repair-tool") or (item.type == "selection-tool")) then
    return true
  else
    return false
  end
end

function igg.update_gui(player, text, amnt)
  try_init()
  if not text then text = igg:get_gui(player.gui.center, "igg_cmd_item").text end
  if not amnt then amnt = igg:get_gui(player.gui.center, "igg_cmd_amount").text end
  if not (text == "") then
    text = string.gsub(text, "%p", "%%%0")
  end
  if not (amnt == "") then
    amnt = string.gsub(amnt, "%p", "%%%0")
  end
  local flow = igg:get_gui(player.gui.center, "igg_cmd_flow")
  if flow.igg_cmd_suggest then
    flow.igg_cmd_suggest.destroy()
  end
  local items = igg.items
  local matches = {}
  local proto = game.item_prototypes
  local list = list(player)
  if show_inventory(player) == true then
    if filter(player) then
      if not (text == "") then
        for _,item in pairs(get_inventory(player)) do
          if string.match(item.name, text) then
            if proto[item.name].has_flag("hidden") and show_hidden(player) then
              if (isListed(list, proto[item.name])) then
                table.insert(matches, {name = item.name, amount = item.amount})
              end
            elseif not proto[item.name].has_flag("hidden") then
              if (isListed(list, proto[item.name])) then
                table.insert(matches, {name = item.name, amount = item.amount})
              end
            end
          end
        end
      end
    else
      matches = get_inventory(player)
    end
  else
    if filter(player) then
      if text == "" then
        return
      end
    else
      text = ""
    end
    if amnt == "" or not tonumber(amnt) or (math.floor(tonumber(amnt)) < 1) then
      amnt = 0
    end
    for _,item in pairs(items) do
      if string.match(item, text) then
        if proto[item].has_flag("hidden") and show_hidden(player) then
          if (isListed(list, proto[item])) then
            table.insert(matches, {name = item, amount = math.floor(tonumber(amnt))})
          end
        elseif not proto[item].has_flag("hidden") then
          if (isListed(list, proto[item])) then
            table.insert(matches, {name = item, amount = math.floor(tonumber(amnt))})
          end
        end
      end
    end
  end
  if #matches > 0 then
    if sort(player) then
      table.sort(matches, function(v1, v2)
        if v1.name < v2.name then
          return true
        elseif v1.name == v2.name then
          if v1.amount < v2.amount then
            return true
          end
        end
      end)
    end
    local suggest = flow.add({type = "scroll-pane", name = "igg_cmd_suggest", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto", style = "igg-scroll-pane", direction = "horizontal"})
    local tab = suggest.add({type = "table", name = "igg_cmd_tab", column_count = (13)})
    for _,match in pairs(matches) do
      tab.add(image(match.name, match.amount))
    end
  end
end

function give(player, i, amount)
  local items = game.item_prototypes
  if items[i] then
    local item = {name = i, count = amount}
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
  local items = game.item_prototypes
  if items[i] then
    local item = {name = i, count = amount}
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