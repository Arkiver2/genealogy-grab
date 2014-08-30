local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')
local url_kind = os.getenv('url_kind')
local url_first = os.getenv('url_first')
local url_second = os.getenv('url_second')
local url_third = os.getenv('url_third')
local url_name = os.getenv('url_name')


read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]

  -- Skip redirect from home.swipnet.se
  if item_type == "genealogy" then
    if string.match(url, "www%.familyorigins%.com") then
      return false
    elseif string.match(url, "familytreemaker%.genealogy%.com") then
      return false
    else
      return verdict
    end
  elseif item_type == "familytreemaker" then
    if string.match(url, "www%.familyorigins%.com") then
      return false
    elseif string.match(url, "www%.genealogy%.com") then
      return false
    else
      return verdict
    end
  elseif item_type == "familyorigins" then
    if string.match(url, "www%.genealogy%.com") then
      return false
    elseif string.match(url, "familytreemaker%.genealogy%.com") then
      return false
    else
      return verdict
    end
  else
    return false
  end
  
  if item_type == "genealogy" or
    item_type == "familytreemaker" or
    item_type == "familyorigins" then
    if string.match(url, "/genealogy/") then
      --example url: http://www.genealogy.com/genealogy/users/s/c/h/Aaron-D-Scholl/
      local url_kind_url = string.match(url, "[a-z]+%.[a-z]+.com/genealogy/([^/]+)/[^/]+/[^/]+/[^/]+/[^/]+/")
      local url_first_url = string.match(url, "[a-z]+%.[a-z]+.com/genealogy/[^/]+/([^/]+)/[^/]+/[^/]+/[^/]+/")
      local url_second_url = string.match(url, "[a-z]+%.[a-z]+.com/genealogy/[^/]+/[^/]+/([^/]+)/[^/]+/[^/]+/")
      local url_third_url = string.match(url, "[a-z]+%.[a-z]+.com/genealogy/[^/]+/[^/]+/[^/]+/([^/]+)/[^/]+/")
      local url_name_url = string.match(url, "[a-z]+%.[a-z]+.com/genealogy/[^/]+/[^/]+/[^/]+/[^/]+/([^/]+)/")
      if url_kind_url ~= url_kind or
        url_first_url ~= url_first or
        url_second_url ~= url_second or
        url_third_url ~= url_third or
        url_name_url ~= url_name then
        return false
      else
        return verdict
      end
    elseif string.match(url, "%.jpg") or
      string.match(url, "%.gif") or
      string.match(url, "%.png") then
      return verdict
    else
      --example url: http://www.genealogy.com/users/s/c/h/Aaron-D-Scholl/
      local url_kind_url = string.match(url, "[a-z]+%.[a-z]+.com/([^/]+)/[^/]+/[^/]+/[^/]+/[^/]+/")
      local url_first_url = string.match(url, "[a-z]+%.[a-z]+.com/[^/]+/([^/]+)/[^/]+/[^/]+/[^/]+/")
      local url_second_url = string.match(url, "[a-z]+%.[a-z]+.com/[^/]+/[^/]+/([^/]+)/[^/]+/[^/]+/")
      local url_third_url = string.match(url, "[a-z]+%.[a-z]+.com/[^/]+/[^/]+/[^/]+/([^/]+)/[^/]+/")
      local url_name_url = string.match(url, "[a-z]+%.[a-z]+.com/[^/]+/[^/]+/[^/]+/[^/]+/([^/]+)/")
      if url_kind_url ~= url_kind or
        url_first_url ~= url_first or
        url_second_url ~= url_second or
        url_third_url ~= url_third or
        url_name_url ~= url_name then
        return false
      else
        return verdict
      end
    end
  else
    return false
  end
end

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]

  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \r")
  io.stdout:flush()

  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    return wget.actions.ABORT
  else
    return wget.actions.NOTHING
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(75, 1000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
