import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Commons

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
        id: modeSubscriber
        command: ["swaymsg", "-t", "subscribe", "--monitor", '["mode", "workspace"]']
        running: true
        onRunningChanged: {if (!running) running = true }
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parsed = JSON.parse(data.trim())
                if(parsed.old === undefined){
                    root.currentMode = parsed.change ?? "default"
                }else if(parsed.change === "reload"){
                    root.currentMode = "default"
                }
            }
        }
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
