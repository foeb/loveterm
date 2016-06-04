file = "loveterm.lua"
wrap = true
no_summary = true
format = 'markdown'
prettify_files = "show"
one = true
examples = "main.lua"
no_lua_ref = true

custom_tags = { { "method", hidden = true } }
custom_display_name_handler = function(item, default_handler)
  if item.type == "function" and item.tags.method then
    return item.name .. item.args .. ' <i style="font-weight: normal;">method</i>'
  end
  return default_handler(item)
end

