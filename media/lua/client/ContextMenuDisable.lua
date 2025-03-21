-- Disable grabbing corpses from the world context menu
OnFillWorldObjectContextMenu = function(_playerNum, _context, _worldobjects, _test)
  if not _test then
      for i = 1, #_context.options do
          local option = _context.options[i]
          if option and option.name then
              -- Remove "Grab Corpse" option when found
              if option.name == getText("ContextMenu_Grab_Corpse") or
                 (tostring(option.name):find("Grab") and tostring(option.name):find("Corpse")) then
                  _context:removeOptionByName(option.name)
              end
          end
      end
  end
end

-- Disable corpse interactions in inventory/container context menu
OnPreFillInventoryObjectContextMenu = function(_playerNum, _context, _items)
    -- Process after the menu is filled but before it's displayed
    local delayedFunc = function()
        for i = #_context.options, 1, -1 do
            local option = _context.options[i]
            if option and option.name then
                -- Remove corpse-related options from containers
                if option.name == getText("ContextMenu_Grab_Corpse") or
                   option.name == getText("ContextMenu_Remove_Corpse") or
                   option.name == getText("ContextMenu_ButcherCorpse") or
                   (tostring(option.name):find("Corpse") and
                   (tostring(option.name):find("Grab") or tostring(option.name):find("Take"))) then

                    _context:removeOptionByName(option.name)
                end
            end
        end
    end

    -- Execute with slight delay to ensure menu is fully populated
    Events.OnTick.Add(function()
        delayedFunc()
        Events.OnTick.Remove(delayedFunc)
    end)
end

if not ContextMenuDisable then ContextMenuDisable = {} end
ContextMenuDisable.onDisable = function(worldObject, playerNum)
  print("Disable option clicked for object")
end

-- Register both event listeners
Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
Events.OnPreFillInventoryObjectContextMenu.Add(OnPreFillInventoryObjectContextMenu)