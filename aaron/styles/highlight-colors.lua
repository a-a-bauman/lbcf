function Pandoc(doc)
  local markdown_text = pandoc.write(doc, 'markdown')

  local replacements = {
    {pattern = "==%[(%w+)%]==(.-)===", html_fmt = '<span style="background-color: %s;">%s</span>', latex_fmt = '\\colorbox{%s}{%s}'},
  }

  local color_map = {
    yellow = {html = "yellow", latex = "yellow"},
    blue = {html = "lightblue", latex = "cyan"},
    green = {html = "lightgreen", latex = "green"},
    pink = {html = "pink", latex = "magenta"}
  }

  for color, values in pairs(color_map) do
    local start_pattern = "==" .. color .. "=="
    local end_pattern = "==/=" .. color .. "=="

    if FORMAT:match 'html' then
      markdown_text = markdown_text:gsub(start_pattern .. "(.-)" .. end_pattern,
                                        '<span style="background-color: ' .. values.html .. ';">%1</span>')
    elseif FORMAT:match 'latex' then
      markdown_text = markdown_text:gsub(start_pattern .. "(.-)" .. end_pattern,
                                        '\\colorbox{' .. values.latex .. '}{%1}')
    end
  end

  return pandoc.read(markdown_text, 'markdown')
end