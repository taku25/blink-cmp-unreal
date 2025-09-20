# blink-cmp-unreal

Unreal Engine C++マクロ指定子のための、コンテキストを認識するblink.cmpソース 🧠 Neovim

<table>
  <tr>
   <td><div align=center>
      <img width="100%" alt="Context-aware completion for UPROPERTY" src="https://raw.githubusercontent.com/taku25/blink-cmp-unreal/images/assets/main_image.png" />
   </div></td>
  </tr>
</table>

`blink-cmp-unreal`は、Unreal EngineのC++開発を加速させるための[blink.cmp](https://github.com/Saghen/blink.cmp)ソースです。カーソルの現在位置にあるマクロ（`UCLASS`, `UPROPERTY`など）を正確に認識し、関連する指定子のみをインテリジェントに補完候補として提供します。

[English](README.md) | [日本語 (Japanese)](README_ja.md)

---

## ✨ 機能 (Features)

*   **コンテキスト認識補完**: 現在カーソルがあるマクロ (`UCLASS`, `UPROPERTY`, `UFUNCTION`, `USTRUCT`, `UENUM`, `UINTERFACE`) に関連する指定子のみを賢く提供します。
*   **インラインドキュメント**: 各補完項目には、その指定子の役割を説明するドキュメントが付随します。
*   **高い設定自由度**: 特定のマクロに対する補完を簡単に有効化・無効化でき、あなたのワークフローに合わせられます。

## 🔧 必要要件 (Requirements)

*   Neovim v0.9.0 以上
*   [**blink.cmp**](https://github.com/Saghen/blink.cmp) (**必須**)

## 🚀 インストール (Installation)

お好みのプラグインマネージャーでインストールしてください。

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- lua/plugins/completion.lua (またはあなたのblink.cmp設定ファイル)
return {
  {
    "Saghen/blink.cmp",
    dependencies = {
      -- blink-cmp-unrealを依存関係に追加
      { "taku25/blink-cmp-unreal" },
    },
    opts = {
      sources = {
        -- "unreal"ソースを有効化
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
      --... その他のblink.cmp設定
    },
  },
}
```

## ⚙️ 設定 (Configuration)

`lazy.nvim`の`dependencies`内で`opts`テーブルを渡すことで、プラグインの動作をカスタマイズできます。

デフォルトでは、すべてのマクロに対する補完が有効になっています。

```lua
-- 例: USTRUCTとUENUMの補完を無効化する
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
  -- ... その他の設定
}
```

### 設定可能なオプション
はい、承知いたしました。
ご提示いただいたMarkdownテーブルに、新しいパラメータとその説明を追加して更新します。

Unreal Engineの各機能に対応する説明を加えました。

### 設定可能なオプション

| オプション | デフォルト値 | 説明 |
| :--- | :---: | :--- |
| `enable_uclass` | `true` | `UCLASS` 指定子の補完を有効にします。 |
| `enable_uproperty` | `true` | `UPROPERTY` 指定子の補完を有効にします。 |
| `enable_ufunction` | `true` | `UFUNCTION` 指定子の補完を有効にします。 |
| `enable_ustruct` | `true` | `USTRUCT` 指定子の補完を有効にします。 |
| `enable_uenum` | `true` | `UENUM` 指定子の補完を有効にします。 |
| `enable_uinterface` | `true` | `UINTERFACE` 指定子の補完を有効にします。 |
| `enable_meta_specifiers` | `true` | `meta` 指定子内で使われるキーワード (`DisplayName`など) の補完を有効にします。 |
| `enable_delegate_macros` | `true` | `DECLARE_DELEGATE` などのデリゲート関連マクロの補完を有効にします。 |
| `enable_module_macros` | `true` | `IMPLEMENT_MODULE` などのモジュール関連マクロの補完を有効にします。 |
| `enable_log_levels` | `true` | `UE_LOG` で使用されるログレベル (`Log`, `Warning`など) の補完を有効にします。 |
| `enable_slate_macros` | `true` | Slate UIフレームワーク関連のマクロ (`SLATE_BEGIN_ARGS`など) の補完を有効にします。 |

## 📜 ライセンス (License)

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
