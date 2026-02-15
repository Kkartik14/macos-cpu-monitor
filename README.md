# CPU Monitor

A minimal macOS menu bar app that shows real-time CPU and memory usage at a glance.

![macOS](https://img.shields.io/badge/macOS-13%2B-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)

## Features

- **Live CPU & Memory gauges** — color-coded rings that shift from green to orange to red as usage increases
- **Top 5 processes** — see what's eating your resources, with app icons
- **1-second refresh** — always up to date
- **Frosted glass UI** — native macOS vibrancy, dark and sleek
- **Zero config** — click the menu bar icon, done

## Download

Head to [**Releases**](../../releases/latest) and download `CPUMonitor.app.zip`. Unzip and drag to Applications.

> macOS may show a Gatekeeper warning since the app isn't signed. Right-click the app and choose **Open** to bypass it.

## Build from source

Requires Xcode Command Line Tools.

```bash
git clone https://github.com/YOUR_USERNAME/cpu-monitor.git
cd cpu-monitor
make run
```

## How it works

Lives in your menu bar as a small `cpu` icon. Click it to see a popover with:

- Two gauge rings (CPU + Memory) inside glass cards
- A list of the top 5 CPU-consuming processes with their app icons

Built with SwiftUI + AppKit. No external dependencies.

## License

MIT
