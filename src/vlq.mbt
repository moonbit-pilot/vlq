///| Base64 character set used for Base64 VLQ encoding.
/// Standard Base64 alphabet: A-Z, a-z, 0-9, +, /
const BASE64_CHARS : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

///| Error types for VLQ operations.
///
/// - `Overflow`: The decoded number exceeds the maximum supported value (0x01FFFFFF)
/// - `IncompleteSequence`: The VLQ sequence is incomplete (missing continuation bytes)
/// - `InvalidBase64Character`: An invalid character was encountered during Base64 VLQ decoding
pub(all) suberror VlqError {
  Overflow
  IncompleteSequence
  InvalidBase64Character(Char)
} derive(Eq, Show)

///| Encodes an array of unsigned integers into Variable Length Quantity (VLQ) byte format.
///
pub fn to_vlq(numbers : Array[UInt]) -> Array[Byte] {
  let bytes : Array[Byte] = []
  for number in numbers {
    let mut value = number
    let encoded_bytes = []
    while true {
      let seven_bits = (value & 0x7F).to_byte()
      encoded_bytes.push(seven_bits)
      value = value >> 7
      if value == 0 {
        break
      }
    }
    encoded_bytes.rev_inplace()
    let len = encoded_bytes.length()
    if len > 1 {
      encoded_bytes[0:len - 1].map_inplace(x => x | 0x80)
    }
    encoded_bytes.each(bytes.push(_))
  }
  bytes
}

///| Decodes Variable Length Quantity (VLQ) bytes back into unsigned integers.
///
/// # Errors:
/// - Overflow: If a number exceeds 0x01FFFFFF (28 bits)
/// - IncompleteSequence: If the sequence ends with a continuation byte
pub fn from_vlq(bytes : Array[Byte]) -> Array[UInt] raise VlqError {
  let numbers : Array[UInt] = []
  let mut current_number : UInt = 0
  let mut in_sequence = false
  for byte in bytes {
    in_sequence = true
    guard current_number <= 0x01FFFFFF else { raise Overflow }
    let seven_bits = (byte & 0x7F).to_uint()
    current_number = (current_number << 7) | seven_bits
    if (byte & 0x80) == 0 {
      numbers.push(current_number)
      current_number = 0
      in_sequence = false
    }
  }
  guard not(in_sequence) else { raise IncompleteSequence }
  numbers
}

///| Creates a mapping from Base64 characters to their corresponding values (0-63).
/// Used for efficient Base64 VLQ decoding.
fn get_base64_map() -> Map[Char, Int] {
  let map = Map::new()
  BASE64_CHARS.iter().eachi((i, c) => map[c] = i)
  map
}

///| Encodes a single signed integer to Base64 VLQ format.
/// 
/// Converts the number to sign-magnitude format, then encodes using 5-bit groups
/// with continuation bits, and finally converts to Base64 characters.
fn encode_single_to_base64_vlq(number : Int) -> String {
  let mut vlq = if number < 0 { (-number << 1) | 1 } else { number << 1 }
  guard vlq != 0 else { "A" }
  let mut encoded = ""
  while vlq > 0 {
    let mut digit = vlq & 0b11111
    vlq = vlq >> 5
    if vlq > 0 {
      digit = digit | 0b100000
    }
    encoded = encoded + BASE64_CHARS.get_char(digit).unwrap().to_string()
  }
  encoded
}

///| Encodes an array of signed integers into Base64 VLQ format.
///
/// # Example
/// ```moonbit
/// let numbers = [1, -1, 16]
/// let encoded = to_base64_vlq(numbers)
/// inspect(encoded, content="CDgB")
/// ```
///
pub fn to_base64_vlq(numbers : Array[Int]) -> String {
  let mut result = ""
  numbers.each(n => result = result + encode_single_to_base64_vlq(n))
  result
}

///| Decodes a Base64 VLQ string back into signed integers.
///
/// # Example
/// ```moonbit
/// let encoded = "CDgB"
/// let decoded = try? from_base64_vlq(encoded)
/// inspect(decoded, content="Ok([1, -1, 16])")
/// ```
///
/// # Errors
/// - `IncompleteSequence`: If the string ends with a continuation character
/// - `InvalidBase64Character`: If an invalid Base64 character is encountered
pub fn from_base64_vlq(s : String) -> Array[Int] raise VlqError {
  let numbers = []
  let mut i = 0
  let len = s.length()
  while i < len {
    let mut vlq = 0
    let mut shift = 0
    let mut continuation = true
    while continuation {
      guard i < len else { raise IncompleteSequence }
      let char = s.get_char(i).unwrap()
      i = i + 1
      match get_base64_map().get(char) {
        None => raise InvalidBase64Character(char)
        Some(digit) => {
          let value_part = digit & 0b11111
          vlq = vlq | (value_part << shift)
          shift = shift + 5
          if (digit & 0b100000) == 0 {
            continuation = false
          }
        }
      }
    }
    let is_negative = (vlq & 1) == 1
    vlq = vlq >> 1
    let number = if is_negative { -vlq } else { vlq }
    numbers.push(number)
  }
  numbers
}
