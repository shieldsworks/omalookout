import QtQuick
import Quickshell
import Quickshell.Io

// Every vessel omakeel has heard, in a window of its own that tiles beside
// the chartplotter. Run standalone (ui/shell.qml) it owns its process; as
// the shell's panel the shell opens and hides it.
Item {
    id: app

    // Set by the Omarchy shell when loaded as a panel.
    property var shell: null
    property var manifest: null
    property bool standalone: true
    property bool opened: standalone

    function open(payload) {
        opened = true;
        Qt.callLater(() => surface.forceActiveFocus());
    }
    function close() {
        opened = false;
    }
    function dismiss() {
        if (standalone) Qt.quit();
        else if (shell) shell.hide("org.omahoy.lookout");
        else opened = false;
    }

    property Theme theme: Theme {}

    // Quickshell keeps a process alive after its last window closes.
    Connections {
        target: Quickshell
        function onLastWindowClosed() { if (app.standalone) Qt.quit(); }
    }

    readonly property var targets: Keel.targets
    readonly property int dangers: Keel.dangers.length
    readonly property string header: {
        if (Keel.incompatible) return "omakeel speaks another protocol version: update omalookout";
        if (!Keel.connected) return "omakeel isn't running";
        const n = targets.length;
        return (n === 1 ? "1 vessel" : n + " vessels") + (dangers ? "  ·  " + dangers + " on a collision course" : "");
    }
    // Ranges and CPAs come only with a current fix; say why they're missing.
    readonly property string fixText: {
        if (!Keel.connected) return "";
        const f = Keel.fix;
        if (!f || f.status === "none") return "GPS  waiting: ranges and CPA need a fix";
        if (f.status === "nofix") return "GPS  no fix: ranges and CPA need one";
        if (f.status === "stale") return "GPS  stale " + f.ageSeconds + " s: ranges paused";
        return "GPS  ok";
    }

    // How long ago, first, so a narrow window cuts the destination rather
    // than the sign of a stale report; then speed, course, class, status
    // and destination.
    function motion(t) {
        const parts = [];
        if (typeof t.ageSeconds === "number" && t.ageSeconds >= 60) parts.push("heard " + Math.round(t.ageSeconds / 60) + " min ago");
        if (typeof t.sogKn === "number") parts.push(t.sogKn.toFixed(1) + " kn");
        if (typeof t.cogDeg === "number") parts.push(String(Math.round(t.cogDeg) % 360).padStart(3, "0") + "°T");
        if (typeof t.class === "string") parts.push("class " + t.class);
        if (typeof t.status === "string") parts.push(t.status);
        if (typeof t.destination === "string" && t.destination !== "") parts.push("to " + t.destination);
        return parts.join("  ·  ");
    }

    function scroll(rows) {
        const most = Math.max(0, list.contentHeight - list.height);
        list.contentY = Math.max(0, Math.min(most, list.contentY + rows * 60));
    }

    function key(e) {
        if (e.key === Qt.Key_J || e.key === Qt.Key_Down) scroll(1);
        else if (e.key === Qt.Key_K || e.key === Qt.Key_Up) scroll(-1);
        else if (e.text === "g") list.contentY = 0;
        else if (e.text === "G") scroll(1e6);
        else if (e.text === "q") dismiss();
        else return;
        e.accepted = true;
    }

    // For checks, where no keyboard can be driven:
    //   quickshell ipc -p ui/shell.qml call omalookout status
    IpcHandler {
        target: "omalookout"
        function status(): string {
            return JSON.stringify({connected: Keel.connected, targets: app.targets.length, dangers: app.dangers,
                                   fix: Keel.fix ? Keel.fix.status : "", opened: app.opened});
        }
    }

    FloatingWindow {
        id: win
        title: "Omalookout"
        visible: app.opened
        onVisibleChanged: {
            if (!visible && app.opened) app.dismiss();
            else if (visible) Qt.callLater(() => surface.forceActiveFocus());
        }
        implicitWidth: Number(Quickshell.env("OMALOOKOUT_WIDTH")) || 520
        implicitHeight: Number(Quickshell.env("OMALOOKOUT_HEIGHT")) || 720
        color: app.theme.background

        component Label: Text {
            color: app.theme.foreground
            font.family: app.theme.font
            font.pixelSize: app.theme.baseSize
            elide: Text.ElideRight
        }

        Item {
            id: surface
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => app.key(e)

            Label {
                id: title
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                text: app.header
                color: app.dangers ? app.theme.red : app.theme.foreground
                font.pixelSize: app.theme.baseSize + 2
                font.bold: true
            }

            Rectangle {
                id: rule
                anchors { left: parent.left; right: parent.right; top: title.bottom; topMargin: 10; leftMargin: 14; rightMargin: 14 }
                height: 1
                color: app.theme.foreground
                opacity: 0.2
            }

            Label {
                anchors { left: parent.left; right: parent.right; top: rule.bottom; margins: 14 }
                visible: list.count === 0
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                opacity: 0.65
                text: Keel.connected
                    ? "No vessels heard in the last 10 minutes. Targets come from omakeel's AIS receiver."
                    : "Start it with an AIS receiver, for example:\nomakeel run --source serial:/dev/ttyACM0:38400"
            }

            ListView {
                id: list
                anchors { left: parent.left; right: parent.right; top: rule.bottom; bottom: statusBar.top; topMargin: 6; leftMargin: 6; rightMargin: 6 }
                clip: true
                spacing: 2
                model: app.targets
                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property var t: modelData
                    // A vessel with no danger field is not a danger.
                    readonly property bool flagged: modelData.danger === true
                    readonly property color tone: flagged ? app.theme.red : app.theme.foreground
                    width: ListView.view.width
                    height: lines.implicitHeight + 14

                    Rectangle {
                        anchors.fill: parent
                        visible: row.flagged
                        color: Qt.alpha(app.theme.red, 0.12)
                    }
                    Column {
                        id: lines
                        x: 8
                        y: 7
                        width: parent.width - 16
                        spacing: 3
                        Item {
                            width: parent.width
                            height: name.implicitHeight
                            Label {
                                id: name
                                anchors { left: parent.left; right: range.left; rightMargin: 12 }
                                text: (row.flagged ? "⚠ " : "") + Keel.called(row.t) + (row.t.kind ? "  " + row.t.kind : "")
                                color: row.tone
                                font.bold: true
                            }
                            Label {
                                id: range
                                anchors.right: parent.right
                                text: Keel.range(row.t)
                                color: row.tone
                            }
                        }
                        Label {
                            width: parent.width
                            text: Keel.approach(row.t)
                            color: row.tone
                            font.bold: row.flagged
                        }
                        Label {
                            width: parent.width
                            visible: text !== ""
                            text: app.motion(row.t)
                            opacity: 0.65
                            font.pixelSize: app.theme.baseSize - 1
                        }
                    }
                }
            }

            // GPS | not for navigation.
            Rectangle {
                id: statusBar
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: app.theme.baseSize + 16
                color: app.theme.background
                Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Qt.alpha(app.theme.foreground, 0.18) }
                Label {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    width: parent.width - notNav.width - 42
                    text: app.fixText
                    color: Keel.fix && Keel.fix.status === "ok" ? app.theme.foreground : app.theme.yellow
                }
                Label {
                    id: notNav
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    text: "Not for navigation"
                    opacity: 0.65
                }
            }
        }
    }

    Component.onCompleted: Qt.callLater(() => surface.forceActiveFocus())
}
