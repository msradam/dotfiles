return {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- Follow the macOS appearance at startup (catppuccin maps light→latte, dark→mocha).
      local appearance = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
      vim.o.background = appearance:find("Dark") and "dark" or "light"
      opts.colorscheme = "catppuccin"
    end,
  },
}
