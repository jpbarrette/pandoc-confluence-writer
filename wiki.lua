-- that is very similar to that of pandoc's HTML writer.
-- There is one new feature: code blocks marked with class 'dot'
-- are piped through graphviz and images are included in the HTML
-- output using 'data:' URLs.
--
-- Invoke with: pandoc -t sample.lua
--
-- Note:  you need not have lua installed on your system to use this
-- custom writer.  However, if you do have lua installed, you can
-- use it to test changes to the script.  'lua sample.lua' will
-- produce informative error messages if your code contains
-- syntax errors.

local image_index = 0

-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- Character escaping
local function escape(s, in_attribute)
   return s:gsub("[<>&\"']",
                 function(x)
                    if x == '<' then
                       return '&lt;'
                    elseif x == '>' then
                       return '&gt;'
                    elseif x == '&' then
                       return '&amp;'
                    elseif x == '"' then
                       return '&quot;'
                    elseif x == "'" then
                       return '&#39;'
                    else
                       return x
                    end
                 end)
end

-- Run cmd on a temporary file containing inp and return result.
local function pipe(cmd, inp)
   local tmp = os.tmpname()
   local tmph = io.open(tmp, "w")
   tmph:write(inp)
   tmph:close()
   local outh = io.popen(cmd .. " " .. tmp,"r")
   local result = outh:read("*all")
   outh:close()
   os.remove(tmp)
   return result
end

-- Blocksep is used to separate block elements.
function Blocksep()
   return "\n"
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- One could use some kind of templating
-- system here; this just gives you a simple standalone HTML file.
function Doc(body, metadata, variables)
   local buffer = {}
   local function add(s)
      table.insert(buffer, s)
   end
   add(body)
   if #notes > 0 then
      for _,note in pairs(notes) do
          add("*" .. note)
      end
  end
   return table.concat(buffer,'\n')
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)
   return escape(s)
end

function Space()
   return " "
end

function LineBreak()
   return "\n"
end

function Para(s)
   return s .. "\n"
end

function Plain(s)
   return s
end

function Emph(s)
   return "_" .. s .. "_"
end

function Strong(s)
   return "*" .. s .. "*"
end

function Subscript(s)
   return "~" .. s .. "~"
end

function Superscript(s)
   return "^" .. s .. "^"
end

function Strikeout(s)
   return '-' .. s .. '-'
end

function Link(s, src, tit)
   return "[" .. s .. "|" .. escape(src,true) .. " " .. escape(tit,true) .. "]"
end

function CaptionedImage(src, s, tit)
	image_index = image_index + 1
	return "!" .. escape(src, true) .. "!\n" .. 'FIGURE ' .. image_index .. ". " .. tit .. "\n"
end

function Image(s, src, tit)
   return "!" .. escape(src,true) .. "!"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
   return "h" .. lev .. ". " .. s .. ""
end

function BlockQuote(s)
   return "{quote}\n" .. s .. "\n{quote}"
end

function HorizontalRule()
   return "----"
end

function Code(s)
    return '{{' .. s .. '}}'
end

function CodeBlock(s, attr)
   return "{code:" .. attr["class"] .. "}" .. s .. "{code}"
end

function BulletList(items)
   local buffer = {}
   for _, item in pairs(items) do
      for line in string.gmatch(item, '([^\n]+)') do
         table.insert(buffer, "*" .. line .. "\n")
      end
   end
   return "\n" .. table.concat(buffer, "") .. "\n"
end

function OrderedList(items)
   local buffer = {}
   for _, item in pairs(items) do
      for line in string.gmatch(item, '([^\n]+)') do
         table.insert(buffer, "#" .. line .. "\n")
      end
   end
   return "\n" .. table.concat(buffer, "\n") .. "\n"
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
   local buffer = {}
   local function add(s)
      table.insert(buffer, s)
   end
   local header_row = {}
   local empty_header = true
   for i, h in pairs(headers) do
      table.insert(header_row, h)
      empty_header = empty_header and h == ""
   end
   if empty_header then
      head = ""
   else
      add('|| ' .. table.concat(header_row, ' || ') .. ' ||')
   end
   for _, row in pairs(rows) do
      add('| ' .. table.concat(row, ' | ') .. ' |')
   end
   return "\n" .. table.concat(buffer,'\n') .. "\n"
end


function Note(s)
  local num = #notes + 1
  -- insert the back reference right before the final closing tag.
  s = string.gsub(s,
          '(.*)</', '%1 <a href="#fnref' .. num ..  '">&#8617;</a></')
  -- add a list item with the note to the note table.
  table.insert(notes, '<li id="fn' .. num .. '">' .. s .. '</li>')
  -- return the footnote reference, linked to the note.
  return '<a id="fnref' .. num .. '" href="#fn' .. num ..
            '"><sup>' .. num .. '</sup></a>'
end



-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index = function(_, key)
   io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
   return function() return "" end
end
setmetatable(_G, meta)

