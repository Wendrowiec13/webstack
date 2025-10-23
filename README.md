# WebStack

A minimal macOS web browser built with SwiftUI and WebKit..

## Features

- **Clean Interface**: Distraction-free browsing with a transparent titlebar and custom window controls
- **Resizable Sidebar**: Adjustable sidebar with navigation controls and URL input
- **Keyboard Shortcuts**:
  - `Cmd+S` - Toggle sidebar visibility
  - `Cmd+Shift+C` - Copy current URL to clipboard
- **Navigation Controls**: Back, forward, and reload buttons with hover effects

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
