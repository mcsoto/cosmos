-- Pathfinder: dependency-free A* pathfinding for rectangular Lua grids.
--
-- local Pathfinder = require("comp.pathfinder")
-- local finder = Pathfinder.new(mapWidth, mapHeight, function(x, y)
--   return tiles[y][x] ~= "wall"
-- end, { diagonal = true })
-- local path, cost = finder:find(1, 1, 12, 8)
-- -- path is {{x=1,y=1}, ..., {x=12,y=8}} or nil, reason

local Pathfinder = {}
Pathfinder.__index = Pathfinder

local SQRT2 = math.sqrt(2)

local function isFiniteNumber(value)
  return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function push(heap, node)
  heap[#heap + 1] = node
  local i = #heap
  while i > 1 do
    local parent = math.floor(i / 2)
    if heap[parent].f <= node.f then break end
    heap[i] = heap[parent]
    i = parent
  end
  heap[i] = node
end

local function pop(heap)
  local first = heap[1]
  local last = heap[#heap]
  heap[#heap] = nil
  if #heap == 0 then return first end
  local i = 1
  while true do
    local left = i * 2
    if left > #heap then break end
    local right = left + 1
    local child = right <= #heap and heap[right].f < heap[left].f and right or left
    if heap[child].f >= last.f then break end
    heap[i] = heap[child]
    i = child
  end
  heap[i] = last
  return first
end

local function manhattan(x, y, gx, gy)
  return math.abs(gx - x) + math.abs(gy - y)
end

local function octile(x, y, gx, gy)
  local dx, dy = math.abs(gx - x), math.abs(gy - y)
  return math.max(dx, dy) + (SQRT2 - 1) * math.min(dx, dy)
end

--- Creates a pathfinder for coordinates from (1, 1) through (width, height).
--- `walkable(x, y)` must return false/nil for blocked cells.
function Pathfinder.new(width, height, walkable, options)
  assert(isFiniteNumber(width) and width >= 1 and width == math.floor(width), "width must be a positive integer")
  assert(isFiniteNumber(height) and height >= 1 and height == math.floor(height), "height must be a positive integer")
  assert(walkable == nil or type(walkable) == "function", "walkable must be a function")
  assert(options==nil or type(options)=="table", "options must be a table")
  options = options or {}
  assert(options.diagonal==nil or type(options.diagonal)=="boolean", "diagonal must be boolean")
  assert(options.allowCornerCutting==nil or type(options.allowCornerCutting)=="boolean", "allowCornerCutting must be boolean")
  assert(options.cost==nil or type(options.cost)=="function", "cost must be a function")
  return setmetatable({
    width = width, height = height,
    walkable = walkable or function() return true end,
    diagonal = options.diagonal == true,
    allowCornerCutting = options.allowCornerCutting == true,
    cost = options.cost,
  }, Pathfinder)
end

function Pathfinder:inBounds(x, y)
  return x >= 1 and y >= 1 and x <= self.width and y <= self.height
end

--- Finds a lowest-cost route. Optional settings override constructor options:
--- diagonal, allowCornerCutting, walkable, cost, maxIterations.
--- Cost callbacks receive (toX, toY, fromX, fromY) and return a positive number.
function Pathfinder:find(startX, startY, goalX, goalY, settings)
  if settings~=nil and type(settings)~="table" then return nil,"invalid_settings" end
  settings = settings or {}
  if (settings.diagonal~=nil and type(settings.diagonal)~="boolean")
    or (settings.allowCornerCutting~=nil and type(settings.allowCornerCutting)~="boolean") then
    return nil,"invalid_settings"
  end
  if not isFiniteNumber(startX) or not isFiniteNumber(startY) or not isFiniteNumber(goalX) or not isFiniteNumber(goalY) then
    return nil, "invalid_coordinates"
  end
  startX, startY, goalX, goalY = math.floor(startX), math.floor(startY), math.floor(goalX), math.floor(goalY)
  if not self:inBounds(startX, startY) or not self:inBounds(goalX, goalY) then return nil, "out_of_bounds" end

  local walkable = settings.walkable or self.walkable
  if type(walkable) ~= "function" then return nil, "invalid_walkable" end
  if not walkable(startX, startY) or not walkable(goalX, goalY) then return nil, "blocked" end
  if startX == goalX and startY == goalY then return {{x=startX, y=startY}}, 0 end

  local diagonal = settings.diagonal
  if diagonal == nil then diagonal = self.diagonal end
  local corners = settings.allowCornerCutting
  if corners == nil then corners = self.allowCornerCutting end
  local costFn = settings.cost or self.cost
  if costFn ~= nil and type(costFn) ~= "function" then return nil, "invalid_cost" end
  -- Unknown terrain weights may be below 1. In that case Dijkstra's zero
  -- heuristic preserves the lowest-cost guarantee for every positive weight.
  local heuristic = costFn and function() return 0 end or (diagonal and octile or manhattan)
  local dirs = diagonal and {{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}} or {{1,0},{-1,0},{0,1},{0,-1}}
  local function key(x, y) return (y - 1) * self.width + x end

  local open, scores, cameFrom, closed = {}, {}, {}, {}
  local startKey = key(startX, startY)
  scores[startKey] = 0
  push(open, {x=startX, y=startY, key=startKey, g=0, f=heuristic(startX, startY, goalX, goalY)})
  local iterations, limit = 0, settings.maxIterations or math.huge
  if type(limit) ~= "number" or limit ~= limit or limit < 0 then return nil, "invalid_iteration_limit" end

  while #open > 0 do
    local node = pop(open)
    -- Old heap entries are left in place instead of requiring a decrease-key operation.
    if not closed[node.key] and node.g == scores[node.key] then
      iterations = iterations + 1
      if iterations > limit then return nil, "iteration_limit" end
      if node.x == goalX and node.y == goalY then
        local path, cursor = {}, node.key
        while cursor do
          local x = ((cursor - 1) % self.width) + 1
          local y = math.floor((cursor - 1) / self.width) + 1
          table.insert(path, 1, {x=x, y=y})
          cursor = cameFrom[cursor]
        end
        return path, node.g
      end
      closed[node.key] = true

      for _, dir in ipairs(dirs) do
        local nx, ny = node.x + dir[1], node.y + dir[2]
        local isDiagonal = dir[1] ~= 0 and dir[2] ~= 0
        if self:inBounds(nx, ny) and walkable(nx, ny) then
          local clearCorner = corners or not isDiagonal or (walkable(node.x + dir[1], node.y) and walkable(node.x, node.y + dir[2]))
          if clearCorner then
            local terrain = costFn and costFn(nx, ny, node.x, node.y) or 1
            if type(terrain) == "number" and terrain > 0 then
              local nextKey = key(nx, ny)
              local newCost = node.g + terrain * (isDiagonal and SQRT2 or 1)
              if not closed[nextKey] and (scores[nextKey] == nil or newCost < scores[nextKey]) then
                scores[nextKey], cameFrom[nextKey] = newCost, node.key
                push(open, {x=nx, y=ny, key=nextKey, g=newCost, f=newCost + heuristic(nx, ny, goalX, goalY)})
              end
            end
          end
        end
      end
    end
  end
  return nil, "no_path"
end

return Pathfinder
