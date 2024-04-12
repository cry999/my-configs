local icons = require('icons')

local function get_palette() return require('catppuccin.palettes').get_palette() end

local function bg() return get_palette().surface1 end

local function tbl_join(base, ...)
  for _, tbl in ipairs({ ... }) do
    for _, item in ipairs(tbl) do
      table.insert(base, item)
    end
  end
  return base
end

local separator = {
  rounded = { left = '', right = '' },
  none = { left = '', right = '' },
  bar = { left = '|', right = '|' },
  inverse = function(sep) return { left = sep.right, right = sep.left } end,
}

local function _true() return true end

---@param cond function?
local function space(cond)
  return { 'space', fmt = function() return ' ' end, color = 'lualine_c_inactive', cond = cond == nil and _true or cond }
end

local center = { { 'center', fmt = function() return '%=' end, separator = separator.none } }

local modes = {
  {
    'mode',
    separator = separator.rounded,
    fmt = function(str) return str:sub(1, 1) end,
    padding = 2,
  },
  {
    'vim',
    separator = separator.rounded,
    fmt = function() return '  ' end,
    color = { fg = get_palette().green, bg = bg() },
  },
  space(),
}

local git = {
  {
    'branch',
    separator = separator.rounded,
    color = { fg = get_palette().surface1, bg = get_palette().peach },
  },
  {
    "diff",
    separator = separator.rounded,
    source = function()
      local gitsigns = vim.b.gitsigns_status_dict
      return gitsigns and {
        added = gitsigns.added,
        modified = gitsigns.changed,
        removed = gitsigns.removed,
      } or {}
    end,
    symbols = {
      added = icons.GitAdd .. " ",
      modified = icons.GitChange .. " ",
      removed = icons.GitDelete .. " ",
    },
    padding = 2,
    diff_color = {
      added = { fg = get_palette().green },
      modified = { fg = get_palette().yellow },
      removed = { fg = get_palette().red },
    },
    cond = nil,
  },
  space(),
}

local recording = {
  {
    'recording-icon',
    separator = separator.rounded,
    fmt = function() return icons.MacroRecording end,
    padding = { right = 1 },
    cond = function() return vim.fn.reg_recording() ~= '' end,
    color = { fg = bg(), bg = get_palette().yellow },
  },
  {
    'macro-recording',
    separator = separator.rounded,
    fmt = function() return vim.fn.reg_recording() end,
    color = { fg = get_palette().yellow },
  },
  space(function() return vim.fn.reg_recording() ~= '' end),
}

local filepath = {
  {
    'path',
    fmt = function()
      local path = vim.fn.expand('%:~:.:h')
      return path == '.' and '' or path:gsub('/', '  ') .. ' '
    end,
    cond = function()
      local path = vim.fn.expand('%:~:.:h')
      local ft = vim.bo[0].filetype
      local bt = vim.bo[0].buftype
      return path ~= '.' and path ~= '' and ft ~= "toggleterm" and bt ~= "help"
    end,
    separator = separator.none,
    color = 'lualine_c_inactive',
  },
  {
    'fileicon',
    separator = separator.none,
    fmt = function()
      if vim.bo[0].filetype == 'toggleterm' then return icons.Terminal end
      if vim.bo[0].buftype == 'help' then return icons.Help end

      local webicons = require("nvim-web-devicons")
      local icon, _ = webicons.get_icon_color(vim.fn.expand('%:t'), vim.fn.expand('%:e'))
      return icon or icons.DefaultFile
    end,
    color = function()
      if vim.bo[0].filetype == 'toggleterm' then return { fg = get_palette().green } end
      if vim.bo[0].buftype == 'help' then return { fg = get_palette().blue } end

      local webicons = require("nvim-web-devicons")
      local _, c = webicons.get_icon_color("", vim.fn.expand('%:e'))
      return { fg = c or get_palette().text }
    end,
  },
  {
    'filename',
    fmt = function()
      if vim.bo[0].filetype == 'toggleterm' then return 'terminal' end
      if vim.bo[0].buftype == 'help' then return vim.fn.expand('%:t:r') or 'help' end

      return vim.fn.expand('%:t') or '[No Name]'
    end,
    separator = separator.none,
  },
  space(),
}

local search = {
  {
    'search-icon',
    separator = separator.rounded,
    fmt = function() return icons.Search end,
    cond = function() return require("noice").api.status.search.has() end,
    color = { fg = bg(), bg = get_palette().yellow },
  },
  {
    'search',
    separator = separator.rounded,
    fmt = function()
      local search = vim.fn.getreg('/')
      local search_count = vim.fn.searchcount()
      return search == '' and '' or search .. ' ' .. search_count.current .. '/' .. search_count.total
    end,
    cond = function() return require("noice").api.status.search.has() end,
    color = { fg = get_palette().yellow },
  },
  space(),
}

local lsp = {
  {
    'diagnostics',
    separator = separator.rounded,
    sources = { 'nvim_diagnostic' },
    symbols = {
      error = icons.DiagnosticError .. ' ',
      hint = icons.DiagnosticHint .. ' ',
      info = icons.DiagnosticInfo .. ' ',
      warn = icons.DiagnosticWarn .. ' ',
    },
  },
  {
    'lsp',
    separator = separator.rounded,
    fmt = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      if not clients or #clients == 0 then
        return nil
      end
      local msg = {}
      for _, client in ipairs(clients) do
        ---@diagnostic disable-next-line: undefined-field
        local fts = client.config.filetypes
        local icon
        if fts and #fts > 0 then
          icon, _ = require("nvim-web-devicons").get_icon_by_filetype(fts[1])
        end
        if client.name == 'copilot' then
          icon = icons.Copilot
        end
        table.insert(msg, (icon or '') .. ' ' .. client.name)
      end
      return table.concat(msg, ' | ')
    end,
    color = { fg = get_palette().surface0, bg = get_palette().red },
  },
}

local windows = {
  {
    'windows',
    separator = separator.rounded,
    section_separators = separator.inverse(separator.rounded),
    icons_enabled = false,
    symbols = {
      alternate_file = '',
    },
    disabled_filetypes = { 'toggleterm', 'help', 'alpha', 'TelescopePrompt', 'neo-tree' },
    disabled_buftypes = { 'terminal', 'nofile', 'help' },
    windows_color = {
      active = { bg = get_palette().blue, fg = bg() },
      inactive = { fg = get_palette().overlay0, bg = bg(), gui = 'italic' },
    },
  },
}

local tabs = {
  {
    'tabs',
    mode = 0,
    separator = separator.rounded,
    section_separators = separator.inverse(separator.rounded),
    tabs_color = {
      active = { bg = get_palette().red, fg = bg() },
      inactive = { fg = get_palette().surface0, bg = bg(), gui = 'italic' },
    },
    show_modified_status = false,
  },
}

return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'catppuccin/nvim',
  },
  config = function()
    require('lualine').setup({
      options = {
        theme = 'catppuccin',
        -- section_separators = separator.inverse(separator.rounded),
        section_separators = separator.none,
        component_separators = separator.bar,
        disabled_filetypes = {
          statusline = { 'alpha' },
          winbar = { 'alpha', 'aerial', 'help', 'toggleterm', 'neo-tree', 'neotest-summary', 'neotest-output' },
        },
      },
      sections = {
        lualine_a = tbl_join(modes),
        lualine_b = tbl_join(git),
        lualine_c = tbl_join(center, filepath),


        lualine_x = {},
        lualine_y = tbl_join(recording, search, lsp),
        lualine_z = {},
      },
      tabline = {
        lualine_a = tbl_join(windows),
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = tbl_join(tabs),
        lualine_z = {},
      },
    })
  end,
}
