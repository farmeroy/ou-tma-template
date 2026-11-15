-- pandoc filter for converting a TMA written with ou-tma-template to docx.
--
-- * The template's centred title block becomes the docx title/author/date
--   metadata, which pandoc renders with the Title, Author and Date styles
-- * The page break after it becomes a section break, so the title page has
--   no header and page numbers start at 1 on the first question
-- * Question headings start a new page through their style, so page breaks
--   just before them are dropped; other page breaks become Word page breaks
-- * Numbered lists get (a)(i) numbering, and lists split by comments are joined

local A4_SECTION = '<w:pgSz w:w="11906" w:h="16838"/>'
  .. '<w:pgMar w:top="2268" w:right="2268" w:bottom="1417" w:left="2268"'
  .. ' w:header="1531" w:footer="992" w:gutter="0"/>'

local TITLE_PAGE_BREAK = pandoc.RawBlock("openxml",
  '<w:p><w:pPr><w:sectPr>' .. A4_SECTION .. '<w:vAlign w:val="center"/></w:sectPr></w:pPr></w:p>')

local PAGE_BREAK = pandoc.RawBlock("openxml", '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

local NUMBER_STYLES = { "LowerAlpha", "LowerRoman" }

local function is_page_break(block)
  return block.t == "Div" and block.classes:includes("page-break")
end

local function is_title_block(block)
  return block.t == "Div" and block.attributes.align == "center"
end

-- Word puts a list item's label on its first paragraph, so an item starting
-- with a table, figure or display equation would lose its label
local function needs_label_paragraph(item)
  local first = item[1]
  if not first then
    return false
  end
  if first.t == "Table" or first.t == "Figure" then
    return true
  end
  return first.t == "Para" and #first.content == 1 and first.content[1].t == "Math"
    and first.content[1].mathtype == "DisplayMath"
end

local fix_blocks

local function fix_list(list, depth)
  for i, item in ipairs(list.content) do
    item = fix_blocks(item, depth + 1)
    if needs_label_paragraph(item) then
      item:insert(1, pandoc.Plain({ pandoc.Str("\u{200B}") }))
    end
    list.content[i] = item
  end
  local style = NUMBER_STYLES[math.min(depth + 1, #NUMBER_STYLES)]
  list.listAttributes = pandoc.ListAttributes(list.listAttributes.start, style, "TwoParens")
  return list
end

-- depth is the number of enclosing numbered lists
fix_blocks = function(blocks, depth)
  local out = pandoc.Blocks({})
  for i, block in ipairs(blocks) do
    local prev = out[#out]
    local next = blocks[i + 1]
    if block.t == "OrderedList" then
      block = fix_list(block, depth)
      if prev and prev.t == "OrderedList" then
        prev.content:extend(block.content)
      else
        out:insert(block)
      end
    elseif is_page_break(block) then
      -- Question headings already start a page (Heading 1 has "page break
      -- before"); a separate break paragraph could spill onto a blank page
      if not (next and next.t == "Header" and next.level == 1) then
        out:insert(PAGE_BREAK)
      end
    elseif block.t == "Div" or block.t == "BlockQuote" or block.t == "Figure" then
      block.content = fix_blocks(block.content, depth)
      out:insert(block)
    elseif block.t == "BulletList" then
      for i, item in ipairs(block.content) do
        block.content[i] = fix_blocks(item, depth)
      end
      out:insert(block)
    else
      out:insert(block)
    end
  end
  return out
end

function Pandoc(doc)
  local blocks = doc.blocks
  if #blocks > 0 and is_title_block(blocks[1]) then
    local paras = blocks[1].content
    doc.meta.title = pandoc.utils.stringify(paras[1] or "")
    doc.meta.author = pandoc.utils.stringify(paras[2] or "")
    -- Match the PDF, which defaults to today's date
    doc.meta.date = paras[3] and pandoc.utils.stringify(paras[3]) or os.date("%Y-%m-%d")
    blocks:remove(1)
    if #blocks > 0 and is_page_break(blocks[1]) then
      blocks[1] = TITLE_PAGE_BREAK
    end
  end
  doc.blocks = fix_blocks(blocks, 0)
  return doc
end
