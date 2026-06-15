# gemini-popup.nvim

A seamless, multi-instance floating terminal plugin for Neovim specifically designed for the `gemini` CLI. It allows you to manage multiple AI chat contexts across different project paths without leaving your editor.

## Why use gemini-popup.nvim?

- **Context Awareness**: Run different Gemini instances for different folders. The plugin tracks them by path.
- **Built-in & Seamless**: No external terminal dependencies. Uses Neovim's native `termopen`.
- **Zero-Config Navigation**: Fast switching between sessions with `<Tab>j/k`.
- **Path Selection**: Integrated `fzf` support for quickly launching Gemini in any subdirectory.
- **Dynamic UI**: Centered floating windows with rounded borders and dynamic titles showing your current path and session count.

## Features

- **Multi-Instance Support**: Toggle and switch between multiple active Gemini sessions.
- **Intelligent Re-use**: Switching to an existing path restores the previous buffer instead of restarting the process.
- **Flexible Keybindings**: Fully configurable global and buffer-local keymaps for Normal, Visual, and Terminal modes.
- **FZF Integration**: Search and select directories directly from within the path input popup.

## Recommended Tools

For the best experience, ensure these are in your system `$PATH`:
- **[fzf](https://github.com/junegunn/fzf)**: Enables the interactive searchable directory list.
- **[fd](https://github.com/sharkdp/fd)**: Used by the plugin for faster, cleaner directory discovery.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "pTSern/gemini-popup.nvim",
    config = function()
        require('gemini-popup').setup({
            -- Optional configuration
            size = {
                horizontal = 0.8,
                vertical = 0.8
            }
        })
    end
}
```

## Usage

### Commands
- `:GeminiPopup [path]` - Opens/switches to a Gemini session at the specified path (defaults to current dir).

### Global Default Keybindings
- `<Leader>gm`: Toggle (open/hide) the current Gemini popup.
- `<Leader>gn`: Create/Switch to a Gemini popup at a custom path (triggers searchable input).
- `<Leader>gk`: Kill the current Gemini session.

### Buffer-Local (Inside Popup)
When inside the popup, you can interact with the terminal normally. To use control keys:
1. Press `<Esc>` to enter **Normal Mode**.
2. Use the following keys:
    - `q`: Hide the popup.
    - `Q`: Kill the current session.
    - `n`: Prompt for a new path.
    - `<Tab>k`: Switch to next session.
    - `<Tab>j`: Switch to previous session.

## Configuration

The `setup` method accepts a table with the following structure (showing defaults):

```lua
require('gemini-popup').setup({
    size = { 
        horizontal = 0.8, 
        vertical = 0.8 
    },
    toggle = { 
        { 
            key = "<Leader>gm", 
            mode = { 'n', 'v', 't' }, 
            desc = "Toggle [G]e[M]ini CLI popup",
            buffer = {
                { key = "q", mode = { 'n', 'v' } },
                { key = "<Esc>", mode = { 't' }, command = [[<C-\><C-n>]] },
            }
        } 
    },
    kill = { 
        { 
            key = "<Leader>gk", 
            mode = { "n", "v", "t" }, 
            desc = "[G]emini Popup will be [K]illed",
            buffer = {
                { key = "Q", mode = { 'n', 'v' } }
            }
        } 
    },
    new = { 
        { 
            key = "<Leader>gn", 
            mode = { 'n', 'v', 't' }, 
            desc = "New Gemini Popup at path",
            buffer = {
                { key = "n", mode = { 'n', 'v' } }
            }
        } 
    },
    next = { 
        { 
            key = "<Tab>k", 
            mode = { 'n', 'v', 't' }, 
            desc = "Next Gemini Popup",
            buffer = {
                { key = "<Tab>k", mode = { 'n', 'v' } }
            }
        } 
    },
    prev = { 
        { 
            key = "<Tab>j", 
            mode = { 'n', 'v', 't' }, 
            desc = "Prev Gemini Popup",
            buffer = {
                { key = "<Tab>j", mode = { 'n', 'v' } }
            }
        } 
    },
})
```
