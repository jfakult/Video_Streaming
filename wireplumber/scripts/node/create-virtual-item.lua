-- WirePlumber
--
-- Copyright © 2021 Collabora Ltd.
--    @author Julian Bouzas <julian.bouzas@collabora.com>
--
-- SPDX-License-Identifier: MIT

-- Receive script arguments from config.lua

-- creates the virtual items defined in the JSON(virtual.conf)

log = Log.open_topic ("s-node")

config = {}
config.virtual_items = Conf.get_section_as_object ("virtual-items")

function createVirtualItem (factory_name, properties)
  -- create virtual item
  local si_v = SessionItem ( factory_name )
  if not si_v then
    log:warning (si_v, "could not create virtual item of type " .. factory_name)
    return
  end

  -- configure virtual item
  if not si_v:configure(properties) then
    log:warning(si_v, "failed to configure virtual item " .. properties.name)
    return
  end

  -- activate and register virtual item
  si_v:activate (Features.ALL, function (item)
    item:register ()
    log:info(item, "registered virtual item " .. properties.name)
  end)
end


for name, properties in pairs(config.virtual_items) do
  properties["name"] = name
  createVirtualItem ("si-audio-virtual", properties)
end
