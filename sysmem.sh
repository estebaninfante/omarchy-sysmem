#!/bin/bash
# SysMem probe for vm.sysmem.
# Prints exactly one JSON line so the QML widget can JSON.parse it:
#   {"ram_used_mb":1234,"ram_total_mb":31319,"vram_used_mb":6600,"vram_total_mb":8176}
# vram_* are omitted when no readable GPU exists.
# VRAM sources, in order: AMD amdgpu sysfs, then NVIDIA nvidia-smi.
mem_total=$(awk '/^MemTotal:/ { print int($2 / 1024) }' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo)
ram_used=$((mem_total - mem_avail))

vram_json=""

# AMD: amdgpu sysfs exposes raw byte counters per card.
for card in /sys/class/drm/card*; do
  [[ $(cat "$card/device/vendor" 2>/dev/null) == "0x1002" ]] || continue
  total=$(cat "$card/device/mem_info_vram_total" 2>/dev/null)
  used=$(cat "$card/device/mem_info_vram_used" 2>/dev/null)
  if [[ $total =~ ^[0-9]+$ && $used =~ ^[0-9]+$ ]]; then
    vram_json=$(printf ',"vram_used_mb":%d,"vram_total_mb":%d' $((used / 1048576)) $((total / 1048576)))
    break
  fi
done

# NVIDIA: nvidia-smi reports MiB directly (nounits drops the "MiB" suffix).
if [[ -z $vram_json ]] && command -v nvidia-smi >/dev/null 2>&1; then
  nv=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')
  nv_used=${nv%%,*}
  nv_total=${nv##*,}
  if [[ $nv_used =~ ^[0-9]+$ && $nv_total =~ ^[0-9]+$ ]]; then
    vram_json=$(printf ',"vram_used_mb":%d,"vram_total_mb":%d' "$nv_used" "$nv_total")
  fi
fi

printf '{"ram_used_mb":%d,"ram_total_mb":%d%s}\n' "$ram_used" "$mem_total" "$vram_json"
