-- Hide secrets while sharing the screen: values in .env files are drawn as asterisks (the file on
-- disk and the buffer text do not change). <leader>ue toggles it, <leader>uE reveals the current line.
-- Names are listed one by one because the plugin has no exclude: .env.example stays readable.
return {
  {
    "laytan/cloak.nvim",
    event = { "BufReadPre .env", "BufReadPre .env.*" },
    cmd = { "CloakToggle", "CloakPreviewLine", "CloakEnable", "CloakDisable" },
    keys = {
      { "<leader>ue", "<cmd>CloakToggle<cr>", desc = "Toggle Secret Masking" },
      { "<leader>uE", "<cmd>CloakPreviewLine<cr>", desc = "Reveal Secret on Line" },
    },
    opts = {
      enabled = true,
      cloak_character = "*",
      cloak_length = nil,
      highlight_group = "Comment",
      patterns = {
        {
          file_pattern = {
            ".env",
            ".env.local",
            ".env.*.local",
            ".env.development",
            ".env.production",
            ".env.staging",
            ".env.test",
          },
          cloak_pattern = "=.+",
        },
      },
    },
  },
}
