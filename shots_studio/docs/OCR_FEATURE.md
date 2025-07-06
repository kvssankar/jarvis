# OCR (Optical Character Recognition) Feature

## Overview

The OCR feature allows users to extract text from screenshots using the Tesseract OCR engine. This feature works completely offline and doesn't require internet connectivity.

## Files Created/Modified

### New Files
- `lib/services/ocr_service.dart` - Core OCR service using Tesseract OCR
- `lib/widgets/ocr_result_dialog.dart` - Dialog to display extracted text
- `test/ocr_service_test.dart` - Unit tests for OCR service

### Modified Files
- `lib/screens/screenshot_details_screen.dart` - Added OCR button and functionality
- `pubspec.yaml` - Added `tesseract_ocr: ^0.5.0` dependency

## Features

1. **Text Extraction**: Extracts text from screenshot images using Tesseract OCR
2. **Offline Processing**: Works completely offline without internet connectivity
3. **Clipboard Integration**: Automatically copies extracted text to clipboard
4. **User-Friendly Dialog**: Shows extracted text in a dialog for review
5. **Error Handling**: Graceful handling of invalid images or OCR failures
6. **Platform Support**: Available on Android and iOS

## Usage

1. Open any screenshot in the Screenshot Details screen
2. Click the text extraction button (🔤) in the bottom navigation bar
3. The app will process the image and extract any text found
4. A dialog will display the extracted text
5. Text is automatically copied to clipboard
6. User can copy the text again if needed

## Technical Details

### Dependencies
- `tesseract_ocr: ^0.5.0` - Flutter plugin for Tesseract OCR engine

### Service Architecture
- **OCRService**: Singleton service handling all OCR operations
- **Modular Design**: Separate concerns for text extraction, clipboard operations, and UI
- **Error Handling**: Comprehensive error handling for various failure scenarios

### Supported Image Sources
- File path-based images (mobile)
- Byte array-based images (web)
- Automatic temporary file creation when needed

### OCR Configuration
- Default language: English (`eng`)
- Extensible language support (see `getSupportedLanguages()`)
- Configurable OCR parameters (future enhancement)

## Testing

The OCR service includes comprehensive unit tests covering:
- Service initialization and singleton pattern
- Platform availability checks
- Invalid image handling
- Clipboard operations
- Error scenarios

Run tests with:
```bash
flutter test test/ocr_service_test.dart
```

## Future Enhancements

1. **Language Selection**: Allow users to select OCR language
2. **OCR Settings**: Configurable OCR parameters (PSM, OEM, etc.)
3. **Text Preprocessing**: Image enhancement before OCR
4. **Batch Processing**: Extract text from multiple screenshots
5. **Text Formatting**: Better text formatting and structure preservation
6. **Search Integration**: Search screenshots by extracted text content

## Limitations

1. OCR accuracy depends on image quality and text clarity
2. Works best with clear, high-contrast text
3. Processing time depends on image size and complexity
4. Language support depends on installed Tesseract language packs
5. Currently supports only basic text extraction (no layout preservation)

## Error Handling

The service handles various error scenarios:
- Invalid or missing image files
- Corrupted image data
- OCR processing failures
- Platform compatibility issues
- Clipboard access failures

All errors are logged and user-friendly messages are displayed through the SnackbarService.
