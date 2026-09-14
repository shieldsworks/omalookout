import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

// The nearest vessel in the bar, in the theme's urgent color while any
// vessel is on a collision course. Click for every vessel heard.
BarWidget {
    id: root
    moduleName: "org.omahoy.lookout"

    // The shape the shell's summon, hide and popout switching expect.
    property bool opened: false
    property bool popoutSwitchClosing: false
    function open() {
        popoutSwitchClosing = false;
        opened = true;
    }
    function close() {
        opened = false;
    }
    function closeForPopoutSwitch() {
        popoutSwitchClosing = true;
        close();
    }

    readonly property var danger: Keel.dangers.length > 0 ? Keel.dangers[0] : null
    readonly property string label: {
        if (Keel.incompatible) return "AIS ?";
        if (!Keel.connected) return "AIS off";
        if (danger) return "⚠ " + Keel.called(danger) + " " + danger.cpaNm.toFixed(2) + " nm";
        if (Keel.nearest) return "AIS " + Keel.targets.length + " · " + Keel.nearest.rangeNm.toFixed(1) + " nm";
        return "AIS " + Keel.targets.length;
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.label
        foreground: root.danger ? Color.urgent : (root.bar ? root.bar.barForeground : Color.foreground)
        dimmed: !Keel.connected
        tooltipText: Keel.connected ? "" : "omakeel isn't running"
        onPressed: b => {
            if (b === Qt.LeftButton) {
                if (root.opened) root.close();
                else root.open();
            }
        }
    }

    KeyboardPanel {
        id: popup
        anchorItem: button
        bar: root.bar
        owner: root
        open: root.opened
        padding: 12
        borderSpec: Border.flat(root.danger ? Color.urgent : Color.accent, 2)
        // Fixed size, as Omastorm does: binding to the loaded list makes the
        // popover jump as it settles.
        contentWidth: 380
        contentHeight: 420
        focusTarget: content.item
        Loader {
            id: content
            anchors.fill: parent
            active: root.opened
            sourceComponent: TargetList {}
        }
    }
}
