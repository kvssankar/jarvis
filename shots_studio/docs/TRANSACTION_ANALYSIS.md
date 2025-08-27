# Transaction Analysis Feature

## Overview

The Transaction Analysis feature allows users to analyze their SMS messages to extract and categorize financial transactions. This feature uses the existing LLM infrastructure (Gemini/Gemma) to intelligently parse transaction messages and provide insights into spending patterns.

## Features

### Core Functionality

- **SMS Permission Management**: Requests and manages SMS read permissions
- **Message Filtering**: Intelligently filters SMS messages that likely contain transaction information
- **LLM-Powered Analysis**: Uses Gemini or Gemma models to extract transaction details
- **Transaction Categorization**: Automatically categorizes transactions by type (shopping, food, transport, etc.)
- **Spending Insights**: Groups transactions by source/bank and provides spending summaries

### Data Extraction

The system extracts the following information from each transaction:

- **Payee Name**: The recipient or merchant name
- **Requestor Name**: The bank or service that sent the message
- **Amount**: Transaction amount (automatically converted to double)
- **Date**: Transaction date and time
- **Description**: Brief description of the transaction
- **Category**: Transaction category (food, transport, shopping, etc.)
- **Type**: Debit or Credit transaction
- **Currency**: Currency code (defaults to INR)

## Architecture

### Models

- **Transaction**: Core transaction data model
- **TransactionSummary**: Grouped transaction data by requestor
- **SmsMessage**: SMS message data model

### Services

- **MessageService**: Handles SMS permission and message reading
- **TransactionAnalysisService**: LLM-powered transaction analysis
- **Integration with existing AIService infrastructure**

### UI Components

- **TransactionAnalysisScreen**: Main screen for transaction analysis
- **FeaturesSection**: New drawer section for accessing features
- **Permission handling UI**: Guides users through SMS permission setup

## Usage

### Accessing the Feature

1. Open the app drawer
2. Navigate to the "Features" section
3. Tap on "Transaction Analysis"

### First Time Setup

1. The app will request SMS permission
2. Grant permission to read SMS messages
3. Tap "Analyze Messages" to start analysis

### Analysis Process

1. The system reads recent SMS messages (last 90 days)
2. Filters messages likely to contain transaction information
3. Processes messages in batches using the configured LLM
4. Extracts transaction details and categorizes them
5. Groups transactions by source and calculates summaries

### Viewing Results

- **Summary View**: Shows total transactions, amount, and sources
- **Grouped View**: Transactions grouped by bank/service
- **Detail View**: Individual transaction details with original message
- **Expandable Cards**: Tap to expand and see all transactions from a source

## Technical Implementation

### Android Integration

- Added SMS read permission to AndroidManifest.xml
- Implemented native SMS reading in MainActivity.kt
- Uses Android's Telephony.Sms content provider

### LLM Integration

- Leverages existing AIService infrastructure
- Supports both Gemini (cloud) and Gemma (local) models
- Implements fallback regex-based extraction for reliability

### Privacy & Security

- All processing is done locally or with user's own API keys
- SMS data is never stored permanently
- Only transaction metadata is retained
- Users can control which messages are analyzed

## Configuration

### Model Selection

The feature works with any configured LLM model:

- **Gemini Models**: Requires API key, processes in cloud
- **Gemma Models**: Local processing, no API key needed

### Batch Processing

- Processes messages in batches of 10 to avoid overwhelming the LLM
- Shows progress during analysis
- Supports cancellation of ongoing analysis

## Error Handling

### Permission Errors

- Clear messaging when SMS permission is denied
- Guidance on how to grant permission manually

### Analysis Errors

- Fallback to regex-based extraction if LLM fails
- Graceful handling of malformed responses
- Progress tracking with error recovery

### Network Errors

- Timeout handling for cloud-based models
- Retry logic for transient failures
- Offline support with local models

## Future Enhancements

### Planned Features

- **Export Functionality**: Export transaction data to CSV/Excel
- **Advanced Filtering**: Filter by date range, amount, category
- **Spending Analytics**: Charts and graphs for spending patterns
- **Budget Tracking**: Set budgets and track spending against them
- **Recurring Transaction Detection**: Identify subscription payments
- **Multi-language Support**: Support for non-English transaction messages

### Technical Improvements

- **Incremental Analysis**: Only analyze new messages since last run
- **Background Processing**: Analyze messages in background
- **Data Persistence**: Store transaction history locally
- **Sync Capabilities**: Sync data across devices

## Testing

### Unit Tests

- Transaction model serialization/deserialization
- SMS message parsing
- Transaction grouping and summarization

### Integration Tests

- SMS permission flow
- LLM integration
- End-to-end transaction analysis

### Manual Testing

- Test with various bank message formats
- Verify accuracy of extracted data
- Test permission handling on different Android versions

## Dependencies

### New Dependencies

- Uses existing `permission_handler` for SMS permissions
- Leverages existing LLM infrastructure
- No additional external dependencies required

### Android Permissions

- `android.permission.READ_SMS`: Required for reading SMS messages

## Performance Considerations

### Memory Usage

- Processes messages in batches to limit memory usage
- Cleans up temporary data after processing
- Efficient JSON parsing and model creation

### Processing Speed

- Batch processing optimizes LLM usage
- Local models (Gemma) provide faster processing
- Progress tracking keeps users informed

### Battery Usage

- Efficient message filtering reduces processing load
- Batch processing minimizes API calls
- Background processing can be optimized for battery life
