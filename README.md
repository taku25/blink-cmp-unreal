# blink-cmp-unreal

A context-aware blink.cmp source for Unreal Engine C++ macro specifiers 🧠 Neovim

<table>
  <tr>
   <td><div align=center>
      <img width="100%" alt="Context-aware completion for UPROPERTY" src="https://raw.githubusercontent.com/taku25/blink-cmp-unreal/assets/main_image.png" />
   </div></td>
  </tr>
</table>

`blink-cmp-unreal` is a [blink.cmp](https://github.com/Saghen/blink.cmp) source designed to accelerate C++ development in Unreal Engine. It accurately recognizes the macro at the current cursor position (such as `UCLASS`, `UPROPERTY`, etc.) and intelligently provides only relevant specifiers as completion candidates.

[English](README.md) | [日本語 (Japanese)](README_ja.md)

---

## ✨ Features

*   **Context-Aware Completion**: Intelligently provides only the specifiers relevant to the macro at the current cursor position (`UCLASS`, `UPROPERTY`, `UFUNCTION`, `USTRUCT`, `UENUM`, `UINTERFACE`).
*   **Inline Documentation**: Each completion item is accompanied by documentation explaining the role of the specifier.
*   **Highly Configurable**: Easily enable or disable completion for specific macros to fit your workflow.

## 🔧 Requirements

*   Neovim v0.9.0 or later
*   [**blink.cmp**](https://github.com/Saghen/blink.cmp) (**required**)

## 🚀 Installation

Install with your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- lua/plugins/completion.lua (or your blink.cmp config file)
return {
  {
    "Saghen/blink.cmp",
    dependencies = {
      -- Add blink-cmp-unreal as a dependency
      { "taku25/blink-cmp-unreal" },
    },
    opts = {
      sources = {
        -- Enable the "unreal" source
        default = { "lsp", "buffer", "path", "unreal" },
        providers = {
          unreal = {
            module = "blink-cmp-unreal",
            name = "unreal",
            score_offset = 15,
            filetypes = { "cpp", "h" },
          },
        },
      },
      --... other blink.cmp settings
    },
  },
}
```

## ⚙️ Configuration

You can customize the plugin's behavior by passing an `opts` table within the `dependencies` section in `lazy.nvim`.

By default, completion for all macros is enabled.

```lua
-- Example: Disable completion for USTRUCT and UENUM
{
  "Saghen/blink.cmp",
  dependencies = {
    {
      "taku25/blink-cmp-unreal",
      opts = {
        enable_ustruct = false,
        enable_uenum = false,
      },
    },
  },
  -- ... other settings
}
```

### Configurable Options

| Option                | Default | Description                               |
| :-------------------- | :-----: | :---------------------------------------- |
| `enable_uclass`       | `true`  | Enables completion for `UCLASS` specifiers.    |
| `enable_uproperty`    | `true`  | Enables completion for `UPROPERTY` specifiers. |
| `enable_ufunction`    | `true`  | Enables completion for `UFUNCTION` specifiers. |
| `enable_ustruct`      | `true`  | Enables completion for `USTRUCT` specifiers.   |
| `enable_uenum`        | `true`  | Enables completion for `UENUM` specifiers.     |
| `enable_uinterface`   | `true`  | Enables completion for `UINTERFACE` specifiers.|

## 📜 License

MIT License

Copyright (c) 2025 taku25

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
