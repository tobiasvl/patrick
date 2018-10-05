--[[
  Lua script that analyzes levels for Patrick's Challenge II and up using
  a brute-force DFS algorithm.

  For each level, it outputs the shortest solution, the total number of
  solutions, and the distribution of the number of solutions per length.

  It's highly recommended to run this in LuaJIT. Even then, execution takes
  about 3.5 hours with the 50 stock Reldni levels.
]]

local preset_levels={
  {27,7,25,6,26,1,15},
  {14,11,5,16,11,6,13},
  {12,27,24,1,10,18,13},
  {20,23,21,28,1,9,21},
  {12,15,13,19,21,1,13},
  {28,14,8,19,14,9,16},
  {8,17,19,20,16,1,10},
  {6,19,13,24,18,13,21},
  {20,11,11,4,25,11,23},
  {1,11,9,23,20,18,6},
  {27,14,8,19,14,9,16},
  {19,22,20,27,28,8,20},
  {2,27,21,4,27,22,1},
  {13,16,14,20,22,2,14},
  {20,18,12,23,17,12,20},
  {25,28,26,5,6,14,26},
  {5,11,11,4,25,11,23},
  {27,10,7,1,18,23,23},
  {4,12,2,11,4,6,20},
  {28,7,25,7,27,1,15},
  {18,25,4,17,14,8,19},
  {3,11,5,16,11,6,13},
  {4,20,16,10,0,0,6},
  {27,8,9,11,6,20,28},
  {5,16,19,23,17,6,11},
  {9,8,17,19,21,16,2},
  {13,20,19,9,17,2,2},
  {20,19,16,26,24,8,20},
  {6,15,17,18,14,27,7},
  {27,20,25,10,23,24,0}, -- ?
  {10,9,5,15,14,26,10},
  {6,10,11,16,1,26,14},
  {27,17,20,3,7,1,18},
  {10,20,17,12,1,5,6},
  {11,19,9,18,11,13,27},
  {4,18,24,21,3,1,13},
  {27,10,7,1,18,23,23},
  {12,20,10,19,12,14,28},
  {18,4,26,9,4,27,7},
  {10,20,17,11,1,5,6},
  {27,14,8,19,14,9,16},
  {14,22,12,21,13,16,2},
  {16,4,26,9,4,27,7},
  {12,0,0,11,0,19,13},
  {24,2,13,20,13,6,21},
  {8,21,15,26,21,16,23},
}

function dfs(level)
  local solutions=0
  local solution_lengths = {}
  local shortest_steps=28
  local shortest_solution=""
  local graph={
    {9,8,2,},
    {10,9,1,8,3,},
    {11,10,2,9,4,},
    {12,11,3,10,5,},
    {13,12,4,11,6,},
    {14,13,5,12,7,},
    {14,6,13,},
    {16,1,15,2,9,},
    {1,17,2,16,8,15,3,10,},
    {2,18,3,17,9,16,4,11,},
    {3,19,4,18,10,17,5,12,},
    {4,20,5,19,11,18,6,13,},
    {5,21,6,20,12,19,7,14,},
    {6,7,21,13,20,},
    {23,8,22,9,16,},
    {8,24,9,23,15,22,10,17,},
    {9,25,10,24,16,23,11,18,},
    {10,26,11,25,17,24,12,19,},
    {11,27,12,26,18,25,13,20,},
    {12,28,13,27,19,26,14,21,},
    {13,14,28,20,27,},
    {15,16,23,},
    {15,16,22,17,24,},
    {16,17,23,18,25,},
    {17,18,24,19,26,},
    {18,19,25,20,27,},
    {19,20,26,21,28,},
    {20,21,27,},
  }

  local add = table.insert
  local concat = table.concat
  function solve_rec(g,v,balls,path)
    g[v].discovered=true
    add(path,v)

    local stuck=true
    for _,w in ipairs(g[v]) do
      if not g[w].discovered then
        stuck=false
      end
    end

    local solved=true
    for _,w in ipairs(g) do
      if not w.discovered then
        solved=false
      end
    end

    if solved then
      solutions = solutions + 1
      if solution_lengths[#path] then
        solution_lengths[#path] = solution_lengths[#path] + 1
      else
        solution_lengths[#path] = 1
      end
      if #path < shortest_steps then
        shortest_steps = #path
        shortest_solution = concat(path, " ")
      end
    end

    for _,w in ipairs(g[v]) do
      if not g[w].discovered then
        local tile=0
        for ball=1,7 do
          if balls[ball]==w then
            tile=ball
            break
          end
        end
        local revert={}

        for _,x in ipairs(g[w]) do
          if (tile==7 or tile==2) and (x==w-6 or x==w-7 or x==w-8) and not g[x].discovered then
            g[x].discovered=true
            add(revert,g[x])
          end
          if (tile==6 or tile==7) and (x==w+6 or x==w+7 or x==w+8) and not g[x].discovered then
            g[x].discovered=true
            add(revert,g[x])
          end
          if (tile==4 or tile==5) and (x==w-8 or x==w-1 or x==w+6) and not g[x].discovered then
            g[x].discovered=true
            add(revert,g[x])
          end
          if (tile==3 or tile==4) and (x==w+8 or x==w+1 or x==w-6) and not g[x].discovered then
            g[x].discovered=true
            add(revert,g[x])
          end
        end
        solve_rec(g,w,balls,path)
        for _,i in ipairs(revert) do
          i.discovered=false
        end
      end
    end
    g[v].discovered=false
    path[#path]=nil
  end
  solve_rec(graph,level[1],level,{})
  return shortest_steps, shortest_solution, solutions, solution_lengths
end

local shortest_steps, shortest_solution, solutions, solution_lengths
for i=1,#preset_levels do
  shortest_steps, shortest_solution, solutions, solution_lengths = dfs(preset_levels[i])
  print("LEVEL " .. i)
  print("Shortest steps: " .. shortest_steps)
  print("Shortest solution: " .. shortest_solution)
  print("Solutions: " .. solutions)
  print("Paths: ")
  for l,n in pairs(solution_lengths) do
    print(l .. ": " .. n)
  end
  print("")
end
