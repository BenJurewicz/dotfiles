import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property string currentMode: "default"

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: capsuleHeight

    visible: currentMode !== "default" && currentMode !== ""
    implicitWidth: visible ? contentWidth : 0
    implicitHeight: contentHeight

    Process {
        id: modePoller
        command: ["swaymsg", "-t", "get_binding_state"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text.trim())
                    root.currentMode = parsed.name ?? "default"
                } catch (e) {
                    root.currentMode = "default"
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: modePoller.running = true
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: Color.mSurfaceVariant
        radius: Style.radiusL
        border.color: Color.mPrimary
        border.width: Style.borderS

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: "keyboard"
                color: Color.mPrimary
            }

            NText {
                text: root.currentMode
                color: Color.mPrimary
                pointSize: barFontSize
                font.weight: Font.Medium
            }
        }
    }
}
