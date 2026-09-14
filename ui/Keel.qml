pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The connection to omakeel, shared by the bar on every monitor. The
// protocol is omakeel's docs/protocol.md: newline-delimited JSON, version 1.
QtObject {
    id: keel

    readonly property int version: 1
    readonly property string path: Quickshell.env("XDG_RUNTIME_DIR") + "/omakeel/keel.sock"

    // The latest `fix` and `targets` from omakeel; empty while disconnected.
    property var fix: null
    property var targets: []
    // omakeel speaks another protocol version: stop, and say so.
    property bool incompatible: false

    readonly property bool connected: socket !== null && socket.connected
    readonly property var dangers: targets.filter(t => t.danger)
    readonly property var nearest: {
        for (let i = 0; i < targets.length; i++) {
            if (targets[i].rangeNm !== undefined) return targets[i];
        }
        return null;
    }

    function receive(line) {
        let message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (message.v !== keel.version) {
            keel.incompatible = true;
            keel.socket.connected = false;
            return;
        }
        if (message.type === "state") keel.fix = message.fix;
        else if (message.type === "targets") keel.targets = message.targets;
        // Other types are ignored, as the protocol asks.
    }

    // A vessel's name, or its MMSI when no name has come yet.
    function called(t) {
        return t.name !== undefined ? t.name : "MMSI " + t.mmsi;
    }

    function range(t) {
        if (t.rangeNm === undefined) return "";
        return t.rangeNm.toFixed(t.rangeNm < 10 ? 2 : 1) + " nm " + String(Math.round(t.bearingDeg) % 360).padStart(3, "0") + "°";
    }

    function approach(t) {
        if (t.lat === undefined) return "no position yet";
        if (t.rangeNm === undefined) return "waiting for our fix";
        if (t.cpaNm === undefined) return "no CPA: course unknown";
        if (t.tcpaMinutes === 0) return "closest now, opening";
        return "CPA " + t.cpaNm.toFixed(2) + " nm in " + t.tcpaMinutes.toFixed(1) + " min";
    }

    property var socket: socketFactory.createObject(keel)
    property Component socketFactory: Component {
        Socket {
            path: keel.path
            connected: true
            parser: SplitParser {
                onRead: data => keel.receive(data)
            }
            onConnectedChanged: {
                if (!connected) {
                    keel.fix = null;
                    keel.targets = [];
                }
            }
        }
    }

    // A failed connect leaves Quickshell's socket allocated, and toggling
    // `connected` can't retry it, so each retry is a fresh Socket, as
    // Omastorm does.
    property Timer reconnect: Timer {
        interval: 2000
        repeat: true
        running: keel.socket !== null && !keel.socket.connected && !keel.incompatible
        onTriggered: {
            const previous = keel.socket;
            keel.socket = keel.socketFactory.createObject(keel);
            previous.destroy();
        }
    }
}
