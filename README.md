# DropSquash

A **tiny floating dropzone** on your macOS desktop. Drag files to instantly compress, convert, or process them.

## ✨ Features

### 🎯 Core Functionality
- **Floating Drop Zone**: Small circular zone that floats on your desktop
- **Single & Multiple Files**: Drop one file or multiple files at once
- **Real-time Progress**: Visual feedback with progress indicators and status messages
- **Smart Processing**: Automatically detects file types and applies appropriate operations

### 🖼️ Image Processing
- **Compression**: Compress JPEG images to 50% quality
- **Format Conversion**:
  - HEIC/HEIF → JPEG
  - PNG → JPEG
  - WebP → JPEG
  - TIFF → JPEG
  - BMP → PNG
  - GIF → PNG (first frame)
- **Size Savings**: Shows compression percentage and file size reduction

### 📄 Document Processing
- **PDF Compression**: Compress PDF files using Quartz filters

### 📋 Utilities
- **Batch Processing**: Process multiple files sequentially with progress tracking

## 🚀 Getting Started

### Requirements
- macOS 12.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

### Building the Project

1. Clone or download this repository
2. Open `DropSquash.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run (⌘R)

### Running the App

1. Launch the app from Xcode or build and run
2. A small circular drop zone will appear in the top-right corner of your screen
3. Drag and drop files onto the zone
4. Watch as files are processed with real-time feedback

## 📖 Usage

### File Type Behavior

| File Type | Action | Output Location |
|-----------|--------|----------------|
| JPEG | Compress (50% quality) | Next to original |
| HEIC/HEIF | Convert to JPEG (85% quality) | Next to original |
| PNG | Convert to JPEG (85% quality) | Next to original |
| WebP | Convert to JPEG (85% quality) | Next to original |
| TIFF | Convert to JPEG (85% quality) | Next to original |
| BMP | Convert to PNG | Next to original |
| GIF | Convert to PNG (first frame) | Next to original |
| PDF | Compress | Next to original |
| Video (MOV/MP4) | Detection only | Info message |
| Other | Copy path to clipboard | Clipboard |

### Output Location
Files are saved next to the original file by default. If that fails, the app attempts to save to Desktop.

## 📄 License

This project is provided as-is for educational and personal use.

**Enjoy your magical file drop zone!** ✨

