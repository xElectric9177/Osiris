{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "~/.config/omarchy/branding/about.txt",
    "color": { "1": "{{ accent }}" },
    "padding": {
      "top": 2,
      "right": 6,
      "left": 2
    }
  },
  "display": {
    "disableLinewrap": true
  },
  "modules": [
    "break",
    "break",
    {
      "type": "custom",
      "format": "\u001b[90m┌──────────────────────Hardware──────────────────────┐"
    },
    {
      "type": "host",
      "key": " PC",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "cpu",
      "key": "│ ├",
      "showPeCoreCount": true,
      "keyColor": "{{ accent }}"
    },
    {
      "type": "gpu",
      "key": "│ ├",
      "detectionMethod": "pci",
      "format": "{name}",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "display",
      "key": "│ ├󱄄",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "disk",
      "key": "│ ├󰋊",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "memory",
      "key": "│ ├",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "swap",
      "key": "└ └󰓡 ",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "custom",
      "format": "\u001b[90m└────────────────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "custom",
      "format": "\u001b[90m┌──────────────────────Software──────────────────────┐"
    },
    {
      "type": "command",
      "key": " OS",
      "keyColor": "{{ cyan }}",
      "text": "version=$(omarchy-version) && echo \"Omarchy $version\""
    },
    {
      "type": "command",
      "key": "│ ├󰘬",
      "keyColor": "{{ cyan }}",
      "text": "omarchy-version-branch"
    },
    {
      "type": "command",
      "key": "│ ├󰔫",
      "keyColor": "{{ cyan }}",
      "text": "channel=$(omarchy-version-channel); echo \"$channel\""
    },
    {
      "type": "kernel",
      "key": "│ ├",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "wm",
      "key": "│ ├",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "de",
      "key": " DE",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "terminal",
      "key": "│ ├",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "packages",
      "key": "│ ├󰏖",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "wmtheme",
      "key": "│ ├󰉼",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "command",
      "key": "│ ├󰸌",
      "keyColor": "{{ cyan }}",
      "text": "theme=$(omarchy-theme-current); echo -e \"$theme \\e[38m●\\e[37m●\\e[36m●\\e[35m●\\e[34m●\\e[33m●\\e[32m●\\e[31m●\""
    },
    {
      "type": "terminalfont",
      "key": "└ └",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "custom",
      "format": "\u001b[90m└────────────────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "custom",
      "format": "\u001b[90m┌────────────────Age / Uptime / Update───────────────┐"
    },
    {
      "type": "command",
      "key": "󱦟 OS Age",
      "keyColor": "{{ magenta }}",
      "text": "echo $(( ($(date +%s) - $(stat -c %W /)) / 86400 )) days"
    },
    {
      "type": "uptime",
      "key": "󱫐 Uptime",
      "keyColor": "{{ magenta }}"
    },
    {
      "type": "command",
      "key": " Update",
      "keyColor": "{{ magenta }}",
      "text": "updated=$(omarchy-version-pkgs); echo \"$updated\""
    },
    {
      "type": "custom",
      "format": "\u001b[90m└────────────────────────────────────────────────────┘"
    },
    "break"
  ]
}
