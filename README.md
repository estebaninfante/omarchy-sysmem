# SysMem

Live RAM + AMD GPU VRAM usage in the [Omarchy](https://omarchy.org/) bar. Each
slot shows `used/total` plus a small vertical level bar — green under 70%,
yellow 70–90%, red at 90% and above — so pressure is visible at a glance
without reading numbers.

![SysMem preview](preview.png)

## Install

```bash
omarchy plugin add https://github.com/jhonoryza/omarchy-sysmem --enable
```

Pick the `right` section when prompted (or any section you prefer).

## Remove

```bash
omarchy plugin remove vm.sysmem
```

Or manually:

1. Delete the plugin folder:
   ```bash
   rm -rf ~/.config/omarchy/plugins/vm.sysmem
   ```
2. Remove the `"id": "vm.sysmem"` entry from the bar layout in `~/.config/omarchy/shell.json`.
3. Restart the shell:
   ```bash
   omarchy restart shell
   ```

## Usage

- The bar shows `M` + RAM used/total and `V` + VRAM used/total (e.g. `M 8.1/31.2G V 6.8/8.0G`).
- Hover for a tooltip with exact percentages.
- Left/middle click refreshes the reading immediately.

## Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `refreshSeconds` | integer 1–10 | 2 | Sampling interval in seconds |

## Requirements

- Omarchy with Quickshell
- `bash`, `awk`
- RAM: always available via `/proc/meminfo`
- VRAM: an AMD GPU with readable `mem_info_vram_*` sysfs nodes (shows `--` otherwise)

## How it works

`sysmem.sh` prints one JSON line per run with RAM used/total (MiB, from
`/proc/meminfo`) and, when present, AMD VRAM used/total (MiB, from
`/sys/class/drm/card*/device/mem_info_vram_*`). `BarWidget.qml` formats the
values and colors the level bars. No daemon, no root, no external dependencies.

## License

[MIT](LICENSE)
