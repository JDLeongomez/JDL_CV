function process_block(el)
  if el.t ~= "Para" and el.t ~= "Plain" then return el end

  local content = el.content
  local new_content = {}
  local i = 1
  local is_important = false

  -- Detecta marcador [important] al inicio
  if content[1] and content[1].t == "Str" and content[1].text == "[important]" then
    is_important = true
    -- Inserta el ícono
    table.insert(new_content, pandoc.RawInline("latex", "\\textcolor{teal}{\\faStar}"))
    table.insert(new_content, pandoc.Space())
    i = 2 -- Saltar el marcador
  end

  while i <= #content do
    local node = content[i]

    -- Detectar y dar formato al nombre
    if node.t == "Str" and node.text == "Leongómez," then
      local next1 = content[i+1]
      local next2 = content[i+2]
      if next1 and next1.t == "Space" and next2 and next2.t == "Str" and next2.text:match("^J%.?%s*D%.?") then
        -- Extraer lo que queda después de las iniciales
        local rest = next2.text:sub((next2.text:find("D%.?") or 0) + 2)
        table.insert(new_content, pandoc.Strong {
          pandoc.Str("Leongómez,"),
          pandoc.Space(),
          pandoc.Str("J."),
          pandoc.Space(),
          pandoc.Str("D.")
        })
        if rest ~= "" then
          table.insert(new_content, pandoc.Str(rest))
        end
        i = i + 3
      else
        table.insert(new_content, node)
        i = i + 1
      end
    else
      table.insert(new_content, node)
      i = i + 1
    end
  end

  el.content = new_content
  return el
end

return {
  { Block = process_block }
}
