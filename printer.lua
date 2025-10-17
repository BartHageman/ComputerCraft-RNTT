local printer = {}

local printer_block = peripheral.find("printer")

function printer:send_rntt(s, m, next)
  if m.type == "ERROR" then
    if not printer_block.newPage() then
      error("Cannot start a new page. Do you have ink and paper?")
    end

    -- Write to the page
    printer_block.setPageTitle("Error report")
    printer_block.write(require("pprint").pformat(m))

    -- And finally print the page!
    if not printer_block.endPage() then
      error("Cannot end the page. Is there enough space?")
    end
  end
  return next(s, m)
end

return printer
