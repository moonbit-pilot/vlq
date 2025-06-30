# VLQ (Variable Length Quantities)

A MoonBit library for encoding and decoding Variable Length Quantities (VLQ) and Base64 VLQ.

## Overview

Variable Length Quantities (VLQ) is a universal code that uses an arbitrary number of bytes to encode arbitrarily large integers. It's commonly used in:

- MIDI files for encoding timing information
- Source maps for encoding mapping information
- Protocol buffers and other binary serialization formats

This library provides:

- Standard VLQ encoding/decoding for unsigned integers
- Base64 VLQ encoding/decoding for signed integers (commonly used in source maps)

## Features

- **Standard VLQ**: Encode/decode arrays of unsigned integers to/from byte arrays
- **Base64 VLQ**: Encode/decode arrays of signed integers to/from Base64 strings
- **Error handling**: Comprehensive error types for overflow and incomplete sequences
- **Memory efficient**: Direct array operations without intermediate allocations

## Usage

### Standard VLQ

```moonbit
// Encode unsigned integers to VLQ bytes
let numbers = [0x7FU, 0x4000U, 0x01FFFFFFU]
let encoded = to_vlq(numbers)
// encoded = [0x7F, 0x81, 0x80, 0x00, 0xFF, 0xFF, 0xFF, 0x7F]

// Decode VLQ bytes back to unsigned integers
let decoded = try? from_vlq(encoded)
// decoded = Ok([0x7F, 0x4000, 0x01FFFFFF])
```

### Base64 VLQ

```moonbit
// Encode signed integers to Base64 VLQ string
let numbers = [1, -1, 16]
let encoded = to_base64_vlq(numbers)
// encoded = "CDgB"

// Decode Base64 VLQ string back to signed integers
let decoded = try? from_base64_vlq("CDgB")
// decoded = Ok([1, -1, 16])
```

## API Reference

### Error Handling

The library defines three error types:

- `Overflow`: When decoding a VLQ sequence that would overflow the maximum supported value
- `IncompleteSequence`: When a VLQ sequence is incomplete (missing continuation bytes)
- `InvalidBase64Character`: When an invalid character is encountered in Base64 VLQ decoding

### Functions

- `to_vlq(Array[UInt]) -> Array[Byte]`: Encode unsigned integers to VLQ bytes
- `from_vlq(Array[Byte]) -> Array[UInt] raise VlqError`: Decode VLQ bytes to unsigned integers
- `to_base64_vlq(Array[Int]) -> String`: Encode signed integers to Base64 VLQ string
- `from_base64_vlq(String) -> Array[Int] raise VlqError`: Decode Base64 VLQ string to signed integers
