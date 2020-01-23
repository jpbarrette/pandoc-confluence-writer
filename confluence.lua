-- This is a sample custom writer for pandoc.  It produces output
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

-- Character escaping
local function escape(s, in_attribute)
  return s:gsub(
    '[<>&"\']',
    function(x)
      if x == "<" then
        return "&lt;"
      elseif x == ">" then
        return "&gt;"
      elseif x == "&" then
        return "&amp;"
      elseif x == '"' then
        return "&quot;"
      elseif x == "'" then
        return "&#39;"
      else
        return x
      end
    end
  )
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x, y in pairs(attr) do
    if y and y ~= "" then
      table.insert(attr_table, " " .. x .. '="' .. escape(y, true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Run cmd on a temporary file containing inp and return result.
local function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " " .. tmp, "r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end

-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n\n"
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.
function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  local css_style =
    [[
<ac:structured-macro ac:macro-id="b7c0ac99-8feb-49c2-858c-870cd55df16b" ac:name="html" ac:schema-version="1">'
    <ac:parameter ac:name="atlassian-macro-output-type">INLINE</ac:parameter>
    <ac:plain-text-body>
    <![CDATA[
 <style>
#captioned-image {
    text-align: center;
}]] ..
    "</style>]]></ac:plain-text-body></ac:structured-macro>"
  add(css_style)
  add(body)
  if #notes > 0 then
    add('<ol class="footnotes">')
    for _, note in pairs(notes) do
      add(note)
    end
    add("</ol>")
  end
  return table.concat(buffer, "\n") .. "\n"
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

function SoftBreak()
  return "\n"
end

function LineBreak()
  return "<br/>"
end

function Emph(s)
  return "<em>" .. s .. "</em>"
end

function Strong(s)
  return "<strong>" .. s .. "</strong>"
end

function Subscript(s)
  return "<sub>" .. s .. "</sub>"
end

function Superscript(s)
  return "<sup>" .. s .. "</sup>"
end

function SmallCaps(s)
  return '<span style="font-variant: small-caps;">' .. s .. "</span>"
end

function Strikeout(s)
  return '<span style="text-decoration: line-through;">' .. s .. "</span>"
end

function Link(s, src, tit, attr)
  if src and string.sub(src, 1, 11) == "confluence:" then
    -- [Page Link](confluence:SPACE:Content Title)
    for space, page in src:gsub("%%20", " "):gmatch("confluence:(%w+):([%w%s]+)") do
      return string.format('<ac:link><ri:page ri:space-key="%s" ' .. 'ri:content-title="%s" /></ac:link>', space, page)
    end
  elseif src and string.sub(src, 1, 1) == "#" then
    -- [Anchor Link](#anchor), taken from https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html#ConfluenceStorageFormat-Links
    return LinkToAnchor(escape(string.sub(src, 2, -1), true), s)
  else
    return "<a href='" .. escape(src, true) .. "' title='" .. escape(tit, true) .. "'>" .. s .. "</a>"
  end
end

function Image(s, src, tit, attr)
  return "<img src='" .. escape(src, true) .. "' title='" .. escape(tit, true) .. "'/>"
end

function Code(s, attr)
  return "<code" .. attributes(attr) .. ">" .. escape(s) .. "</code>"
end

function InlineMath(s)
  return "\\(" .. escape(s) .. "\\)"
end

function DisplayMath(s)
  return "\\[" .. escape(s) .. "\\]"
end

function AnchorRef(anchorName)
  return '<ac:structured-macro ac:name="anchor"><ac:parameter ac:name="">' ..
    anchorName .. "</ac:parameter></ac:structured-macro>"
end

function LinkToAnchor(anchorName, text)
  return '<ac:link ac:anchor="' .. anchorName .. '"><ac:link-body>' .. text .. "</ac:link-body></ac:link>"
end

function Note(s)
  local num = #notes + 1
  -- add a list item with the note to t[he note table.
  table.insert(notes, "<li>" .. AnchorRef("fn" .. num) .. s .. LinkToAnchor("fnref" .. num, "&#8617;") .. "</li>")
  -- return the footnote reference, linked to the note.
  return "<sup>" .. AnchorRef("fnref" .. num) .. LinkToAnchor("fn" .. num, num) .. "</sup>"
end

function Span(s, attr)
  return "<span" .. attributes(attr) .. ">" .. s .. "</span>"
end

function RawInline(format, str)
  if format == "html" then
    return str
  else
    return ""
  end
end

function Cite(s, cs)
  local ids = {}
  for _, cit in ipairs(cs) do
    table.insert(ids, cit.citationId)
  end
  return '<span class="cite" data-citation-ids="' .. table.concat(ids, ",") .. '">' .. s .. "</span>"
end

function Plain(s)
  return s
end

function Para(s)
  return "<p>" .. s .. "</p>"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
  local attr_table = {}
  local prefix = ""
  for x, y in pairs(attr) do
    if y and y ~= "" then
      if x == "id" then
        prefix = prefix .. AnchorRef(y)
      else
        attr_table[x] = y
      end
    end
  end

  return prefix .. "<h" .. lev .. attributes(attr_table) .. ">" .. s .. "</h" .. lev .. ">"
end

function BlockQuote(s)
  return "<blockquote>\n" .. s .. "\n</blockquote>"
end

function HorizontalRule()
  return "<hr/>"
end

function LineBlock(ls)
  return '<div style="white-space: pre-line;">' .. table.concat(ls, "\n") .. "</div>"
end

function CodeBlock(s, attr)
  -- If code block has class 'dot', pipe the contents through dot
  -- and base64, and include the base64-encoded png as a data: URL.
  if attr.class and string.match(" " .. attr.class .. " ", " dot ") then
    -- otherwise treat as code (one could pipe through a highlighter)
    local png = pipe("base64", pipe("dot -Tpng", s))
    return '<img src="data:image/png;base64,' .. png .. '"/>'
  else
    return "<pre><code" .. attributes(attr) .. ">" .. escape(s) .. "</code></pre>"
  end
end

function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<li>" .. item .. "</li>")
  end
  return "<ul>\n" .. table.concat(buffer, "\n") .. "\n</ul>"
end

function OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<li>" .. item .. "</li>")
  end
  return "<ol>\n" .. table.concat(buffer, "\n") .. "\n</ol>"
end

-- Revisit association list STackValue instance.
function DefinitionList(items)
  local buffer = {}
  for _, item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer, "<dt>" .. k .. "</dt>\n<dd>" .. table.concat(v, "</dd>\n<dd>") .. "</dd>")
    end
  end
  return "<dl>\n" .. table.concat(buffer, "\n") .. "\n</dl>"
end

-- Convert pandoc alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
function html_align(align)
  if align == "AlignLeft" then
    return "left"
  elseif align == "AlignRight" then
    return "right"
  elseif align == "AlignCenter" then
    return "center"
  else
    return "left"
  end
end

function table.shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function CaptionedImage(src, tit, caption, attr)
  local prefix = ""
  if attr and attr["id"] ~= "" then
    prefix = AnchorRef(attr["id"])
  end

  attr_cpy = table.shallow_copy(attr)
  attr_cpy["id"] = "captioned-image"
  return Div(
    '<table><tbody><tr><td><ac:image><ri:attachment ri:filename="' ..
      escape(src, true) .. '" /></ac:image></td></tr><tr><td>' .. escape(caption) .. "</td></tr></tbody></table>",
    attr_cpy
  )
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("<table>")
  add("<tbody>")
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    table.insert(header_row, '<th align="' .. align .. '">' .. h .. "</th>")
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add("<th>")
    for _, h in pairs(header_row) do
      add(h)
    end
    add("</th>")
  end
  local class = "even"
  for _, row in pairs(rows) do
    class = (class == "even" and "odd") or "even"
    add("<tr>")
    for i, c in pairs(row) do
      add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. "</td>")
    end
    add("</tr>")
  end
  add("</tbody>")
  add("</table>")
  return table.concat(buffer, "\n")
end

function RawBlock(format, str)
  if format == "html" then
    return str
  else
    return ""
  end
end

function Div(s, attr)
  local div_text =
    [[
<ac:structured-macro ac:macro-id="57855606-2855-47df-ac05-f2cb358f1e23" ac:name="div" ac:schema-version="1">]]
  for x, y in pairs(attr) do
    if y and y ~= "" then
      div_text = div_text .. string.format('  <ac:parameter ac:name="%s">%s</ac:parameter>', x, y)
    end
  end

  div_text = div_text .. string.format("  <ac:rich-text-body>%s</ac:rich-text-body>\n</ac:structured-macro>", s)
  return div_text
end

function DoubleQuoted(s)
  return "&laquo;" .. s .. "&raquo;"
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index = function(_, key)
  io.stderr:write(string.format("WARNING: Undefined function '%s'\n", key))
  return function()
    return ""
  end
end
setmetatable(_G, meta)
