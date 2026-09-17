import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar widget showing live memory pressure:
//   RAM used/total + AMD VRAM used/total, values turn red above 90%.
// Samples come from sysmem.sh (/proc/meminfo + amdgpu sysfs), one JSON line
// per tick; all math and formatting lives here.
BarWidget {
  id: root
  moduleName: "vm.sysmem"

  property real ramUsedMb: 0
  property real ramTotalMb: 1
  property real vramUsedMb: -1
  property real vramTotalMb: 1

  readonly property int refreshSeconds: Math.max(1, Math.min(10, Number(setting("refreshSeconds", 2)) || 2))
  readonly property real ramPct: ramTotalMb > 0 ? (ramUsedMb / ramTotalMb) * 100 : 0
  readonly property real vramPct: vramTotalMb > 0 && vramUsedMb >= 0 ? (vramUsedMb / vramTotalMb) * 100 : -1

  function fmtGb(mb) {
    return (mb / 1024).toFixed(1) + "G"
  }

  readonly property string ramText: fmtGb(ramUsedMb) + "/" + fmtGb(ramTotalMb)
  readonly property string vramText: vramUsedMb < 0 ? "--" : fmtGb(vramUsedMb) + "/" + fmtGb(vramTotalMb)
  readonly property string tooltip: "RAM " + ramText + " (" + Math.round(ramPct) + "%)"
    + (vramUsedMb < 0 ? "" : "\nVRAM " + vramText + " (" + Math.round(vramPct) + "%)")

  // Fixed width from the widest string so the bar never shifts.
  readonly property real valueWidth: measureValue.implicitWidth
  readonly property real iconWidth: measureIcon.implicitWidth
  readonly property real groupWidth: 5 + 4 + iconWidth + 4 + valueWidth
  readonly property real fixedRowWidth: groupWidth * 2 + 8

  Text {
    id: measureValue
    visible: false
    text: "99.9/99.9G"
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    id: measureIcon
    visible: false
    text: "M"
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  function apply(line) {
    let data
    try {
      data = JSON.parse(String(line).trim())
    } catch (e) {
      return
    }
    if (!data) return
    root.ramUsedMb = Number(data.ram_used_mb) || 0
    root.ramTotalMb = Number(data.ram_total_mb) || 1
    root.vramUsedMb = ("vram_used_mb" in data) ? Number(data.vram_used_mb) : -1
    root.vramTotalMb = Number(data.vram_total_mb) || 1
  }

  function levelColor(pct) {
    if (pct >= 90) return "#f7768e"
    if (pct >= 70) return "#e5c07b"
    return "#3fb950"
  }

  function refresh() {
    if (!probe.running) probe.running = true
  }

  visible: true
  implicitWidth: root.vertical ? Style.bar.statusSlot : (root.fixedRowWidth + 16)
  implicitHeight: root.vertical ? (col.implicitHeight + 12) : root.barSize

  IpcHandler {
    target: "vm.sysmem"

    function refresh(): void {
      root.broadcast("refresh")
    }
  }

  Process {
    id: probe
    command: ["/bin/bash", Qt.resolvedUrl("sysmem.sh").toString().replace("file://", "")]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.apply(text)
    }
  }

  Timer {
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  component MemGroup: Row {
    property string icon
    property string value
    property real pct: 0
    property real iconWidth: 0
    property real valueWidth: 0
    property color barColor: "#3fb950"
    property real textWidth: iconWidth + 4 + valueWidth
    width: 5 + 4 + textWidth
    spacing: 4
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      width: 5
      height: 16
      radius: 2
      color: "#2c313a"
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height * Math.max(0, Math.min(100, pct)) / 100
        radius: 2
        color: barColor
      }
    }

    Row {
      width: textWidth
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        width: iconWidth
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: icon
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        color: Color.accent
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        width: valueWidth
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: value
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        color: Color.foreground
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  Row {
    id: row
    visible: !root.vertical
    anchors.centerIn: parent
    width: root.fixedRowWidth
    spacing: 8

    MemGroup {
      icon: "M"
      value: root.ramText
      pct: root.ramPct
      iconWidth: root.iconWidth
      valueWidth: root.valueWidth
      barColor: root.levelColor(root.ramPct)
    }

    MemGroup {
      icon: "V"
      value: root.vramText
      pct: root.vramPct
      iconWidth: root.iconWidth
      valueWidth: root.valueWidth
      barColor: root.levelColor(root.vramPct)
    }
  }

  Column {
    id: col
    visible: root.vertical
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "M " + root.ramText
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      color: root.ramPct >= 90 ? "#f7768e" : Color.foreground
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 44
      height: 3
      radius: 2
      color: root.levelColor(root.ramPct)
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "V " + root.vramText
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      color: root.vramPct >= 90 ? "#f7768e" : Color.foreground
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 44
      height: 3
      radius: 2
      color: root.levelColor(root.vramPct)
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: root.refresh()
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
