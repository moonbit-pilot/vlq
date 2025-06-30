///|
test "Encode single byte" {
  assert_eq(to_vlq([0x7F]), [0x7F])
}

///|
test "Encode multiple bytes" {
  assert_eq(to_vlq([0x4000]), [0x81, 0x80, 0x00])
}

///|
test "Decode single byte" {
  assert_eq(try? from_vlq([0x7F]), Ok([0x7F]))
}

///|
test "Decode incomplete standard sequence" {
  let result = try? from_vlq([0x81])
  assert_true(result is Err(IncompleteSequence))
}

///|
test "Decode overflow standard sequence" {
  let result = try? from_vlq([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F])
  assert_true(result is Err(Overflow))
}

///|
test "Encode and decode roundtrip" {
  let numbers = [0x7FU, 0x4000, 0x01FFFFFF]
  let encoded = to_vlq(numbers)
  let decoded = try? from_vlq(encoded)
  assert_eq(decoded, Ok(numbers))
}

///|
test "Decode empty array" {
  let result = try? from_vlq([])
  assert_eq(result, Ok([]))
}

///|
test "Base64 编码" {
  assert_eq(to_base64_vlq([0]), "A")
  assert_eq(to_base64_vlq([1]), "C")
  assert_eq(to_base64_vlq([-1]), "D")
  assert_eq(to_base64_vlq([16]), "gB")
  assert_eq(to_base64_vlq([-16]), "hB")
}

///|
test "Base64 Encoding" {
  assert_eq(to_base64_vlq([1, -1, 16]), "CDgB")
}

///|
test "Base64 Decoding" {
  assert_eq(try? from_base64_vlq("A"), Ok([0]))
  assert_eq(try? from_base64_vlq("C"), Ok([1]))
  assert_eq(try? from_base64_vlq("D"), Ok([-1]))
  assert_eq(try? from_base64_vlq("gB"), Ok([16]))
  assert_eq(try? from_base64_vlq("hB"), Ok([-16]))
  inspect(try? from_base64_vlq("2H"), content="Ok([123])")
  inspect(try? from_base64_vlq("qxmvrH"), content="Ok([123456789])")
  assert_eq(try? from_base64_vlq("2HwcqxB"), Ok([123, 456, 789]))
}

///|
test "Base64 Encoding with multiple numbers" {
  assert_eq(try? from_base64_vlq("CDgB"), Ok([1, -1, 16]))
}

///|
test "Incomplete Base64 sequence" {
  let result = try? from_base64_vlq("g") // 'g' 的连续位是 1
  assert_true(result is Err(IncompleteSequence))
}

///|
test "Invalid Base64 character" {
  let result = try? from_base64_vlq("A!B")
  assert_true(result is Err(InvalidBase64Character('!')))
}
