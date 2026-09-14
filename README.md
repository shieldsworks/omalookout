# Omalookout

AIS targets and collision alarms for [Omahoy](https://github.com/shieldsworks/omahoy).

Omalookout is an Omarchy bar widget. The bar shows the nearest vessel. When
any vessel will pass within 0.5 nm in the next 12 minutes, the bar turns
the theme's urgent color and names it. Click for every vessel heard,
nearest first, with range, bearing, and closest point of approach.

**Status: early.** It works with [omakeel](https://github.com/shieldsworks/omakeel)'s
AIS on a replayed sail. It hasn't met a real AIS receiver yet.

## How it works

Omalookout draws; [omakeel](https://github.com/shieldsworks/omakeel) listens. The hub
decodes AIS from a receiver like the dAISy, keeps every vessel heard in the
last 10 minutes, and works out each one's CPA against the boat's fix. It
flags collisions even with the laptop closed. Omalookout reads the hub's
`targets` over its socket, so it needs omakeel running:

```sh
omakeel run --source serial:/dev/ttyUSB0:4800 --source serial:/dev/ttyACM0:38400
```

In the bar:

- `AIS 3 · 0.8 nm`: three vessels, the nearest 0.8 nm off.
- `⚠ BAY RUNNER 0.19 nm`: a vessel on a collision course, and its CPA.
- `AIS off`: omakeel isn't running. Omalookout reconnects on its own.

The colors and font come from the active Omarchy theme.

## Install

Omarchy 4 on x86_64 or aarch64, with omakeel installed.

```sh
omarchy plugin add https://github.com/shieldsworks/omalookout.git --enable
```

To open the list from the keyboard, add one line to
`~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + A", "Omalookout", "omarchy shell shell toggle org.omahoy.lookout '{}'")
```

## Develop

Link this checkout in place of an installed copy:

```sh
scripts/link-plugin.sh           # link and enable
scripts/link-plugin.sh --unlink  # back to the installed copy
```

The shell doesn't follow the link for changes, so run `omarchy restart shell`
after editing. To try it without a boat, replay omakeel's sample sail. It
has a ferry set to cross 0.2 nm from the boat:

```sh
cd ../omakeel && mise replay
```

## Not for navigation

Omalookout is not a primary means of collision avoidance. Keep a lookout.

## License

MIT
