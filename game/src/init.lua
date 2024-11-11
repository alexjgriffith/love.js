-- mostly based on repl.lua from Fengari itself:
-- https://github.com/fengari-lua/fengari.io/blob/master/static/lua/web-cli.lua
package.path = "./?.lua;./src/?.lua"
local js = require "js"
os.getenv = function() return nil end -- fennel 0.3.0 won't load without this
fennel = require "lib.fennel"


function prepend(tbl,new)
   for i=0, #tbl do
      local j = #tbl - i
      tbl[j + 1] = tbl[j]
   end
   tbl[1]=new
end
package.loaded.fennel = fennel
fennel.path = "./src/?.fnl"
local fennel_searcher = fennel.make_searcher({correlate=true})

package.searchers[3]=nil
package.searchers[4]=nil
-- package.searchers[3] = package.searchers[2]
package.searchers[3] = fennel_searcher

local tmp_searcher = package.searchers[4]

pp = function(x) print(require("lib.fennelview")(x)) end

local welcome = "Welcome to Fennel " .. fennel.version ..
   ", running on Fengari (" .. _VERSION .. ")"

package.jspath=""

-- the hacks below are needed specifically to get the Fennel test suite to pass
-- just make a few things not blow up
_G.os.exit = function() end
_G.os.getenv = function() end

-- require-macros depends on io.open; we splice in a hacky replacement
io={open=function(filename)
       return {
          read = function(_, all)
             assert(all=="*all", "Can only read *all.")
             local xhr = js.new(js.global.XMLHttpRequest)
             xhr:open("GET", filename, false)
             xhr:send()
             assert(xhr.status == 200, xhr.status .. ": " .. xhr.statusText)
             return tostring(xhr.response)
          end,
          close = function() end,
       }
end}

package.preload.fennelview = assert(loadfile("lib/fennelview.lua"))
package.preload.fennelfriend = assert(loadfile("lib/fennelfriend.lua"))

-- Save references to lua baselib functions used
local _G = _G
local pack = table.pack
local tostring = tostring

local document = js.global.document
local output = document:getElementById("fengari-console")
local prompt = document:getElementById("fengari-prompt")
local input = document:getElementById("fengari-input")
-- local luacode = document:getElementById("compiled-lua")
assert(output and prompt and input)

local function triggerEvent(el, type)
    local e = document:createEvent("HTMLEvents")
    e:initEvent(type, false, true)
    el:dispatchEvent(e)
end

local history = {}
local historyIndex = nil
local historyLimit = 100

local function highlightLines(target, elements)
   for i = 0, #elements-1 do
      if tonumber(elements[i]:getAttribute("history")) == target then
         elements[i].style.backgroundColor = (elements[i].style.backgroundColor == "") and "pink" or ""
      else
         elements[i].style.backgroundColor = ""
      end
   end
end

local function makeLine(...)
    local toprint = pack(...)

    local line = document:createElement("pre")
    line.style["white-space"] = "pre-wrap"

    line:setAttribute("history", #history)

    line.onclick = function()
       local n = tonumber(line:getAttribute("history"))

       highlightLines(n, output.children)
       highlightLines(n, luacode.children)
    end

    for i = 1, toprint.n do
        if i ~= 1 then
            line:appendChild(document:createTextNode("\t"))
        end
        line:appendChild(document:createTextNode(tostring(toprint[i])))
    end

    return line
end

_G.printLuacode = function(...)
   local line = makeLine(...)

   luacode:appendChild(line)
   luacode.scrollTop = luacode.scrollHeight
   triggerEvent(luacode, "change")
end


local function debug (str)
   js.global.console.log(null, "debug - " .. str)
end


-- fennel.eval("(each [key value (pairs _G.debug)] (print key)) (print (_G.debug.getinfo))")
_G.print = function(...)
   local line = makeLine(...)

   output:appendChild(line)
   output.scrollTop = output.scrollHeight
   triggerEvent(output, "change")
end


_G.print(welcome)

-- _G.printLuacode("Compiled Lua code")

_G.narrate = function(...)
    local line = makeLine(...)
    line.style.color = "blue"

    output:appendChild(line)

    output.scrollTop = output.scrollHeight
    triggerEvent(output, "change")
end

_G.printError = function(...)
   local line = makeLine(...)
   line.style.color = "red"

   output:appendChild(line)

   output.scrollTop = output.scrollHeight
   triggerEvent(output, "change")
end

local repl = coroutine.create(fennel.dofile("repl.fnl"))

coroutine.resume(repl)

function input.onkeydown(_, e)
    if not e then
        e = js.global.event
    end

    local key = e.key or e.which
    if key == "Enter" and not e.shiftKey then
        historyIndex = nil
        if #input.value > 0 then
           if history[#history] ~= input.value then
              table.insert(history, input.value)
              if #history > historyLimit then
                 table.remove(history, 1)
              end
           end
           coroutine.resume(repl, input.value)
           input.value = ""
        end
        return false
    elseif key == "ArrowUp" or key == "Up" then
        if historyIndex then
            if historyIndex > 1 then
                historyIndex = historyIndex - 1
            end
        else -- start with more recent history item
            local hist_len = #history
            if hist_len > 0 then
                historyIndex = hist_len
            end
        end
        input.value = history[historyIndex]
        return false
    elseif key == "ArrowDown" or key == "Down" then
        local newvalue = ""
        if historyIndex then
            if historyIndex < #history then
                historyIndex = historyIndex + 1
                newvalue = history[historyIndex]
            else -- no longer in history
                historyIndex = nil
            end
        end
        input.value = newvalue
        return false
    elseif key == "l"
        and e.ctrlKey
        and not e.shiftKey
        and not e.altKey
        and not e.metaKey
        and not e.isComposing then
        -- Ctrl+L clears screen like you would expect in a terminal
        output.innerHTML = ""
        _G.print(welcome)
        return false
    end
end


coroutine.resume(repl, "(local okai (require :okai))")

coroutine.resume(repl, "(pp okai.controls)")

coroutine.resume(repl, "(okai.init)")

return repl
