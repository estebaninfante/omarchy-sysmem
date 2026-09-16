#!/bin/bash
# SysMem probe for vm.sysmem.
# Prints exactly one JSON line so the QML widget can JSON.parse it:
#   {"ram_used_mb":1234,"ram_total_mb":31319,"vram_used_mb":6600,"vram_total_mb":8176}
# vram_* are omitted when no readable amdgpu card exists.
mem_total=$(awk '/^MemTotal:/ { print int($2 / 1024) }' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo)
ram_used=$((mem_total - mem_avail))

vram_json=""
for card in /sys/class/drm/card*; do
  [[ $(cat "$card/device/vendor" 2>/dev/null) == "0x1002" ]] || continue
  total=$(cat "$card/device/mem_info_vram_total" 2>/dev/null)
  used=$(cat "$card/device/mem_info_vram_used" 2>/dev/null)
  if [[ $total =~ ^[0-9]+$ && $used =~ ^[0-9]+$ ]]; then
    vram_json=$(printf ',"vram_used_mb":%d,"vram_total_mb":%d' $((used / 1048576)) $((total / 1048576)))
    break
  fi
done

printf '{"ram_used_mb":%d,"ram_total_mb":%d%s}\n' "$ram_used" "$mem_total" "$vram_json"
