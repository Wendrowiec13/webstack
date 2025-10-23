# WebStack

A minimal macOS web browser built with SwiftUI and WebKit..

## Features

- **Clean Interface**: Distraction-free browsing with a transparent titlebar and custom window controls
- **Resizable Sidebar**: Adjustable, collapsible sidebar with vertical tabs navigation controls and URL input
- **Keyboard Shortcuts**:
  - `Cmd+S` - Toggle sidebar visibility
  - `Cmd+Shift+C` - Copy current URL to clipboard
  - `Cmd+T` - New tab
- **Navigation Controls**: Back, forward, and reload buttons
- **Persistent Tabs**: Close the browser and come back to your tabs

## Requirements

- macOS 15.5+
- Xcode 15.0+
- Swift 5.9+

## Building

```bash
./build.sh Debug
```

The built application will be located at `build/Build/Products/Debug/WebStack.app`

## Running

```bash
open build/Build/Products/Debug/WebStack.app
```
