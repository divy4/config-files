-- yay v13 init.lua - AUR Security Configuration

yay.opt.devel = false
yay.opt.clean_after = true
yay.opt.sort_by = 'votes'
yay.opt.diff_menu = true
yay.opt.edit_menu = true

-- Skip recently modified AUR packages (5 day cooldown)
yay.create_autocmd('UpgradeSelect', {
  callback = function(event)
    local exclude = {}
    local cutoff = os.time() - (5 * 24 * 3600)
    for _, pkg in ipairs(event.data.upgrades) do
      if pkg.repository == 'aur' and pkg.last_modified >= cutoff then
        yay.log.warn('Excluding recently modified:', pkg.name)
        table.insert(exclude, pkg.name)
      end
    end
    return { exclude = exclude, skip_menu = false }
  end,
})

-- Block suspicious PKGBUILD patterns
yay.create_autocmd('AURPreInstall', {
  callback = function(event)
    local blocked = {
      'curl.*|.*sh', 'wget.*|.*bash', 'eval%(',
      'rm %-rf /', 'chmod 777', 'base64 %-d',
    }
    for _, pattern in ipairs(blocked) do
      if event.data.pkgbuild:match(pattern) then
        yay.abort('[BLOCKED] Suspicious: ' .. pattern)
      end
    end
  end,
})

-- Warn (don't exclude) when package's maintainer changes.
local cache_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/yay"
local cache_file = cache_dir .. "/maintainer_cache"

local function load_cache()
  local cache = {}
  local f = io.open(cache_file, "r")
  if not f then return cache end
  for line in f:lines() do
    local name, maintainer = line:match("^([^=]+)=(.*)$")
    if name then
      cache[name] = maintainer
    end
  end
  f:close()
  return cache
end

local function save_cache(cache)
  os.execute('mkdir -p "' .. cache_dir .. '"')
  local f = assert(io.open(cache_file, "w"))
  for name, maintainer in pairs(cache) do
    f:write(name .. "=" .. maintainer .. "\n")
  end
  f:close()
end

yay.create_autocmd("UpgradeSelect", {
  desc = "warn on AUR maintainer changes",
  callback = function(event)
    yay.log.info("checking for AUR maintainer changes")
    local cache = load_cache()
    local dirty = false

    for _, pkg in ipairs(event.data.upgrades) do
      if pkg.repository == "aur" and pkg.maintainer ~= "" then
        local cached = cache[pkg.name]
        if cached == nil then
          -- First time seeing this package: seed the cache silently.
          cache[pkg.name] = pkg.maintainer
          dirty = true
        elseif cached == pkg.maintainer then
          yay.log.debug("match correct: " .. pkg.name .. " " .. pkg.maintainer)
        else
          yay.log.error("new maintainer, double check build files: ", pkg.name,
            "(was: " .. cached .. ", now: " .. pkg.maintainer .. ")")
          cache[pkg.name] = pkg.maintainer
          dirty = true
        end
      end
    end

    if dirty then
      yay.log.info("saving maintainer cache:", cache_file)
      save_cache(cache)
    end

    return { exclude = {}, skip_menu = false }
  end,
})
