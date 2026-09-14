import QtQuick
import qs.Commons

// Every vessel omakeel has heard, nearest first, with any danger in the
// theme's urgent color.
Item {
    id: root
    focus: true

    readonly property color ink: Color.foreground
    // Secondary lines are the text color, faded. The theme's muted color is
    // too dark to read on the popover.
    readonly property real faint: 0.65
    readonly property string family: Style.font.family

    Text {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        text: {
            if (Keel.incompatible) return "omakeel speaks another protocol version";
            if (!Keel.connected) return "omakeel isn't running";
            const n = Keel.targets.length;
            const dangers = Keel.dangers.length;
            return (n === 1 ? "1 vessel" : n + " vessels") + (dangers ? " · " + dangers + " on a collision course" : "");
        }
        color: Keel.dangers.length ? Color.urgent : root.ink
        font.family: root.family
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
    }

    Text {
        id: empty
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        visible: list.count === 0
        wrapMode: Text.WordWrap
        text: Keel.connected
            ? "No vessels heard in the last 10 minutes. Targets come from omakeel's AIS receiver."
            : "Start it with an AIS receiver, for example:\nomakeel run --source serial:/dev/ttyACM0:38400"
        color: root.ink
        opacity: root.faint
        font.family: root.family
        font.pixelSize: Style.font.caption
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 6
        model: Keel.targets
        delegate: Item {
            required property var modelData
            readonly property var t: modelData
            readonly property color tone: t.danger ? Color.urgent : root.ink
            width: ListView.view.width
            height: 38

            Text {
                id: name
                anchors.left: parent.left
                anchors.right: distance.left
                anchors.rightMargin: 8
                text: (t.danger ? "⚠ " : "") + Keel.called(t) + (t.kind ? "  " + t.kind : "")
                color: tone
                font.family: root.family
                font.pixelSize: Style.font.body
                font.bold: t.danger
                elide: Text.ElideRight
            }
            Text {
                id: distance
                anchors.right: parent.right
                text: Keel.range(t)
                color: tone
                font.family: root.family
                font.pixelSize: Style.font.body
            }
            Text {
                anchors.top: name.bottom
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.right: parent.right
                // A report this old is shown carried forward; say how old.
                text: Keel.approach(t) + (t.ageSeconds >= 180 ? " · report " + Math.round(t.ageSeconds / 60) + " min old" : "")
                color: t.danger ? Color.urgent : root.ink
                opacity: t.danger ? 1 : root.faint
                font.family: root.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
            }
        }
    }
}
