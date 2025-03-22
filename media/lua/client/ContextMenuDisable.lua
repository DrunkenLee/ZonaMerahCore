Events.OnGameStart.Add(function()
  local ISInventoryTransferAction_start_origin = ISInventoryTransferAction.start
  local ISInventoryTransferAction_perform_origin = ISInventoryTransferAction.perform
  local ISInventoryTransferAction_update_origin = ISInventoryTransferAction.update

  function ISInventoryTransferAction:start()
      if self.srcContainer:getType() == "floor" then
          local worldItem = self.item:getWorldItem()
          if self.character:getVehicle() then
              self.character:StopAllActionQueue()
              local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
              queue:clearQueue()
              self.character:PlayAnim("Idle")
              self.character:Say("Can't grab items from the ground while in a vehicle!")
              self.stopOnWalk = true
              self.stopOnRun = true
              self.maxTime = -1
              self.ignoreAction = true
              return
          end
      end
      ISInventoryTransferAction_start_origin(self)
  end

  function ISInventoryTransferAction:update()
      if self.srcContainer:getType() == "floor" and self.character:getVehicle() then
          self.character:StopAllActionQueue()
          local queue = ISTimedActionQueue.getTimedActionQueue(self.character)
          queue:clearQueue()
          self.character:Say("Can't grab items from the ground while in a vehicle!")
          self.stopOnWalk = true
          self.stopOnRun = true
          self.maxTime = -1
          return
      end
      ISInventoryTransferAction_update_origin(self)
  end

  function ISInventoryTransferAction:perform()
      if self.srcContainer:getType() == "floor" and self.character:getVehicle() then
          self.character:Say("Can't grab items from the ground while in a vehicle!")
          ISInventoryPage.dirtyUI()
          ISInventoryPage.refreshBackpacks()
          return
      end
      ISInventoryTransferAction_perform_origin(self)
  end
end)

local function printContextMenu(context, prefix)
  print("----------- " .. prefix .. " CONTEXT MENU OPTIONS -----------")
  for i = 1, #context.options do
      local option = context.options[i]
      if option and option.name then
          print(i .. ": " .. tostring(option.name))
      else
          print(i .. ": <unnamed option>")
      end
  end
  print("---------------------------------------------")
end

OnFillWorldObjectContextMenu = function(_playerNum, _context, _worldobjects, _test)
  if not _test then
      for i = 1, #_context.options do
          local option = _context.options[i]
          if option and option.name then
              if option.name == getText("ContextMenu_Grab_Corpse") or
                 (tostring(option.name):find("Grab") and tostring(option.name):find("Corpse")) then
                  _context:removeOptionByName(option.name)
              end
          end
      end

      for i = 1, #_context.options do
          local option = _context.options[i]
          if option and option.name then
              print("Option name: " .. option.name)
              if option.name == getText("ContextMenu_Grab") or
                 option.name:find("Grab") or
                 option.name:find("Equip") or
                 option.name:find("Primary") or
                 option.name:find("Secondary") then
              end
          end
      end
  end
end

OnPreFillInventoryObjectContextMenu = function(_playerNum, _context, _items)
  local delayedFunc = function()
      for i = #_context.options, 1, -1 do
          local option = _context.options[i]
          if option and option.name then
              if option.name == getText("ContextMenu_Grab_Corpse") or
                 option.name == getText("ContextMenu_Remove_Corpse") or
                 option.name == getText("ContextMenu_ButcherCorpse") or
                 (tostring(option.name):find("Corpse") and
                 (tostring(option.name):find("Grab") or tostring(option.name):find("Take"))) then
                  _context:removeOptionByName(option.name)
              else
                  if option.name == getText("ContextMenu_Grab") or
                     option.name == getText("ContextMenu_Equip_Primary") or
                     option.name == getText("ContextMenu_Equip_Secondary") or
                     option.name == getText("ContextMenu_Equip_on_Back") then
                      return function () return false end
                  end
              end
          end
      end
  end

  Events.OnTick.Add(function()
      delayedFunc()
      Events.OnTick.Remove(delayedFunc)
  end)
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
Events.OnPreFillInventoryObjectContextMenu.Add(OnPreFillInventoryObjectContextMenu)