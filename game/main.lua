-- bootstrap the compiler

fennel = require("lib.fennel").install({correlate=true,
                                        moduleName="lib.fennel"})

package.loaded.fennel = fennel

-- fennel.path = love.filesystem.getSource() .. "/?.fnl;" ..
--    -- love.filesystem.getSource() .. "/src/?.fnl;" ..
--    -- "/src/?.fnl;" ..
--    "/?.fnl;" ..
--    fennel.path

-- https://love2d.org/forums/viewtopic.php?t=83142
love.filesystem.setRequirePath("?.lua;?/init.lua;src/?.lua;")



pp = function (text)
   -- print (fennel.view (text))
   -- io.flush()
end

local _ptext =""
pp1 = function (text)
   local ntext = fennel.view(text)
   if (_ptext ~= ntext)
   then
      _ptext = ntext
      print (fennel.view (text))
      io.flush()
   end
end


local make_love_searcher = function(env)
   return function(module_name)
      local path = module_name:gsub("%.", "/") .. ".fnl"
      if love.filesystem.getInfo(path) then
         return function(...)
            local code = love.filesystem.read(path)
            return fennel.eval(code, {env=env}, ...)
         end, path
      end
   end 
end

table.insert(package.loaders, make_love_searcher(_G))
table.insert(fennel["macro-searchers"], make_love_searcher("_COMPILER"))

-- taken from bump
function rect_isIntersecting(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and x2 < x1+w1 and
         y1 < y2+h2 and y2 < y1+h1
end

function pointWithin(px,py,x,y,w,h)
  return px < x + w  and px > x and
         py < y + h and py > y
end

math.randomseed( os.time() )

require("src.run")

require("src.wrap")




