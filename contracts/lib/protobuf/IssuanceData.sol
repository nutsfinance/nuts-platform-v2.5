// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;
import "./ProtoBufRuntime.sol";
import "./Payables.sol";

library IssuanceData {

  //enum definition
// Solidity enum definitions
enum IssuanceState {
    IssuanceStateUnknown,
    Initiated,
    Engageable,
    Cancelled,
    PartialComplete,
    Complete
  }


// Solidity enum encoder
function encode_IssuanceState(IssuanceState x) internal pure returns (int64) {
    
  if (x == IssuanceState.IssuanceStateUnknown) {
    return 0;
  }

  if (x == IssuanceState.Initiated) {
    return 1;
  }

  if (x == IssuanceState.Engageable) {
    return 2;
  }

  if (x == IssuanceState.Cancelled) {
    return 3;
  }

  if (x == IssuanceState.PartialComplete) {
    return 4;
  }

  if (x == IssuanceState.Complete) {
    return 5;
  }
  revert();
}


// Solidity enum decoder
function decode_IssuanceState(int64 x) internal pure returns (IssuanceState) {
    
  if (x == 0) {
    return IssuanceState.IssuanceStateUnknown;
  }

  if (x == 1) {
    return IssuanceState.Initiated;
  }

  if (x == 2) {
    return IssuanceState.Engageable;
  }

  if (x == 3) {
    return IssuanceState.Cancelled;
  }

  if (x == 4) {
    return IssuanceState.PartialComplete;
  }

  if (x == 5) {
    return IssuanceState.Complete;
  }
  revert();
}


  //struct definition
  struct Data {
    uint256 issuanceId;
    uint256 instrumentId;
    address makerAddress;
    uint256 issuanceCreation;
    uint256 issuanceDue;
    IssuanceData.IssuanceState issuanceState;
    bytes issuanceProperties;
    EngagementData.Data[] engagements;
    Payable.Data[] payables;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal 
    pure 
    returns (Data memory, uint) 
  {
    Data memory r;
    uint[10] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_issuanceId(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_instrumentId(pointer, bs, r, counters);
      }
      else if (fieldId == 3) {
        pointer += _read_makerAddress(pointer, bs, r, counters);
      }
      else if (fieldId == 4) {
        pointer += _read_issuanceCreation(pointer, bs, r, counters);
      }
      else if (fieldId == 5) {
        pointer += _read_issuanceDue(pointer, bs, r, counters);
      }
      else if (fieldId == 6) {
        pointer += _read_issuanceState(pointer, bs, r, counters);
      }
      else if (fieldId == 7) {
        pointer += _read_issuanceProperties(pointer, bs, r, counters);
      }
      else if (fieldId == 8) {
        pointer += _read_engagements(pointer, bs, nil(), counters);
      }
      else if (fieldId == 9) {
        pointer += _read_payables(pointer, bs, nil(), counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    pointer = offset;
    r.engagements = new EngagementData.Data[](counters[8]);
    r.payables = new Payable.Data[](counters[9]);

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_issuanceId(pointer, bs, nil(), counters);
      }
      else if (fieldId == 2) {
        pointer += _read_instrumentId(pointer, bs, nil(), counters);
      }
      else if (fieldId == 3) {
        pointer += _read_makerAddress(pointer, bs, nil(), counters);
      }
      else if (fieldId == 4) {
        pointer += _read_issuanceCreation(pointer, bs, nil(), counters);
      }
      else if (fieldId == 5) {
        pointer += _read_issuanceDue(pointer, bs, nil(), counters);
      }
      else if (fieldId == 6) {
        pointer += _read_issuanceState(pointer, bs, nil(), counters);
      }
      else if (fieldId == 7) {
        pointer += _read_issuanceProperties(pointer, bs, nil(), counters);
      }
      else if (fieldId == 8) {
        pointer += _read_engagements(pointer, bs, r, counters);
      }
      else if (fieldId == 9) {
        pointer += _read_payables(pointer, bs, r, counters);
      }
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_issuanceId(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.issuanceId = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_instrumentId(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.instrumentId = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_makerAddress(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (address x, uint256 sz) = ProtoBufRuntime._decode_sol_address(p, bs);
    if (isNil(r)) {
      counters[3] += 1;
    } else {
      r.makerAddress = x;
      if (counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_issuanceCreation(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.issuanceCreation = x;
      if (counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_issuanceDue(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[5] += 1;
    } else {
      r.issuanceDue = x;
      if (counters[5] > 0) counters[5] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_issuanceState(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    IssuanceData.IssuanceState x = decode_IssuanceState(tmp);
    if (isNil(r)) {
      counters[6] += 1;
    } else {
      r.issuanceState = x;
      if(counters[6] > 0) counters[6] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_issuanceProperties(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[7] += 1;
    } else {
      r.issuanceProperties = x;
      if (counters[7] > 0) counters[7] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_engagements(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (EngagementData.Data memory x, uint256 sz) = _decode_EngagementData(p, bs);
    if (isNil(r)) {
      counters[8] += 1;
    } else {
      r.engagements[r.engagements.length - counters[8]] = x;
      if (counters[8] > 0) counters[8] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_payables(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[10] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (Payable.Data memory x, uint256 sz) = _decode_Payable(p, bs);
    if (isNil(r)) {
      counters[9] += 1;
    } else {
      r.payables[r.payables.length - counters[9]] = x;
      if (counters[9] > 0) counters[9] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_EngagementData(uint256 p, bytes memory bs)
    internal 
    pure 
    returns (EngagementData.Data memory, uint) 
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (EngagementData.Data memory r, ) = EngagementData._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Payable(uint256 p, bytes memory bs)
    internal 
    pure 
    returns (Payable.Data memory, uint) 
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Payable.Data memory r, ) = Payable._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal 
    pure 
    returns (uint) 
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    pointer += ProtoBufRuntime._encode_key(
      1, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.issuanceId, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      2, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.instrumentId, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      3, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_address(r.makerAddress, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      4, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.issuanceCreation, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      5, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.issuanceDue, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      6, 
      ProtoBufRuntime.WireType.Varint, 
      pointer, 
      bs
    );
    int64 _enum_issuanceState = encode_IssuanceState(r.issuanceState);
    pointer += ProtoBufRuntime._encode_enum(_enum_issuanceState, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      7, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.issuanceProperties, pointer, bs);
    for(i = 0; i < r.engagements.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        8, 
        ProtoBufRuntime.WireType.LengthDelim, 
        pointer, 
        bs)
      ;
      pointer += EngagementData._encode_nested(r.engagements[i], pointer, bs);
    }
    for(i = 0; i < r.payables.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        9, 
        ProtoBufRuntime.WireType.LengthDelim, 
        pointer, 
        bs)
      ;
      pointer += Payable._encode_nested(r.payables[i], pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal 
    pure 
    returns (uint) 
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    e += 1 + 35;
    e += 1 + 35;
    e += 1 + 23;
    e += 1 + 35;
    e += 1 + 35;
    e += 1 + ProtoBufRuntime._sz_enum(encode_IssuanceState(r.issuanceState));
    e += 1 + ProtoBufRuntime._sz_lendelim(r.issuanceProperties.length);
    for(i = 0; i < r.engagements.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(EngagementData._estimate(r.engagements[i]));
    }
    for(i = 0; i < r.payables.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(Payable._estimate(r.payables[i]));
    }
    return e;
  }

  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    // output.issuanceId = input.issuanceId;
    // output.instrumentId = input.instrumentId;
    // output.makerAddress = input.makerAddress;
    // output.issuanceCreation = input.issuanceCreation;
    // output.issuanceDue = input.issuanceDue;
    // output.issuanceState = input.issuanceState;
    // output.issuanceProperties = input.issuanceProperties;

    // output.engagements.length = input.engagements.length;
    // for(uint256 i8 = 0; i8 < input.engagements.length; i8++) {
    //   EngagementData.store(input.engagements[i8], output.engagements[i8]);
    // }
    

    // output.payables.length = input.payables.length;
    // for(uint256 i9 = 0; i9 < input.payables.length; i9++) {
    //   Payable.store(input.payables[i9], output.payables[i9]);
    // }
    

  }


  //array helpers for Engagements
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addEngagements(Data memory self, EngagementData.Data memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    EngagementData.Data[] memory tmp = new EngagementData.Data[](self.engagements.length + 1);
    for (uint256 i = 0; i < self.engagements.length; i++) {
      tmp[i] = self.engagements[i];
    }
    tmp[self.engagements.length] = value;
    self.engagements = tmp;
  }

  //array helpers for Payables
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addPayables(Data memory self, Payable.Data memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    Payable.Data[] memory tmp = new Payable.Data[](self.payables.length + 1);
    for (uint256 i = 0; i < self.payables.length; i++) {
      tmp[i] = self.payables[i];
    }
    tmp[self.payables.length] = value;
    self.payables = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library IssuanceData

library EngagementData {

  //enum definition
// Solidity enum definitions
enum EngagementState {
    EngagementStateUnknown,
    Initiated,
    Active,
    Cancelled,
    Complete,
    Delinquent
  }


// Solidity enum encoder
function encode_EngagementState(EngagementState x) internal pure returns (int64) {
    
  if (x == EngagementState.EngagementStateUnknown) {
    return 0;
  }

  if (x == EngagementState.Initiated) {
    return 1;
  }

  if (x == EngagementState.Active) {
    return 2;
  }

  if (x == EngagementState.Cancelled) {
    return 3;
  }

  if (x == EngagementState.Complete) {
    return 4;
  }

  if (x == EngagementState.Delinquent) {
    return 5;
  }
  revert();
}


// Solidity enum decoder
function decode_EngagementState(int64 x) internal pure returns (EngagementState) {
    
  if (x == 0) {
    return EngagementState.EngagementStateUnknown;
  }

  if (x == 1) {
    return EngagementState.Initiated;
  }

  if (x == 2) {
    return EngagementState.Active;
  }

  if (x == 3) {
    return EngagementState.Cancelled;
  }

  if (x == 4) {
    return EngagementState.Complete;
  }

  if (x == 5) {
    return EngagementState.Delinquent;
  }
  revert();
}


  //struct definition
  struct Data {
    uint256 engagementId;
    address takerAddress;
    uint256 engagementCreation;
    uint256 engagementDue;
    EngagementData.EngagementState engagementState;
    bytes customProperties;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal 
    pure 
    returns (Data memory, uint) 
  {
    Data memory r;
    uint[7] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_engagementId(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_takerAddress(pointer, bs, r, counters);
      }
      else if (fieldId == 3) {
        pointer += _read_engagementCreation(pointer, bs, r, counters);
      }
      else if (fieldId == 4) {
        pointer += _read_engagementDue(pointer, bs, r, counters);
      }
      else if (fieldId == 5) {
        pointer += _read_engagementState(pointer, bs, r, counters);
      }
      else if (fieldId == 6) {
        pointer += _read_customProperties(pointer, bs, r, counters);
      }
      
      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_engagementId(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.engagementId = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_takerAddress(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (address x, uint256 sz) = ProtoBufRuntime._decode_sol_address(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.takerAddress = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_engagementCreation(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[3] += 1;
    } else {
      r.engagementCreation = x;
      if (counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_engagementDue(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (uint256 x, uint256 sz) = ProtoBufRuntime._decode_sol_uint256(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.engagementDue = x;
      if (counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_engagementState(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    EngagementData.EngagementState x = decode_EngagementState(tmp);
    if (isNil(r)) {
      counters[5] += 1;
    } else {
      r.engagementState = x;
      if(counters[5] > 0) counters[5] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_customProperties(
    uint256 p, 
    bytes memory bs, 
    Data memory r, 
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[6] += 1;
    } else {
      r.customProperties = x;
      if (counters[6] > 0) counters[6] -= 1;
    }
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal 
    pure 
    returns (uint) 
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    pointer += ProtoBufRuntime._encode_key(
      1, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.engagementId, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      2, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_address(r.takerAddress, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      3, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.engagementCreation, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      4, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_sol_uint256(r.engagementDue, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      5, 
      ProtoBufRuntime.WireType.Varint, 
      pointer, 
      bs
    );
    int64 _enum_engagementState = encode_EngagementState(r.engagementState);
    pointer += ProtoBufRuntime._encode_enum(_enum_engagementState, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      6, 
      ProtoBufRuntime.WireType.LengthDelim, 
      pointer, 
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.customProperties, pointer, bs);
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal 
    pure 
    returns (uint) 
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + 35;
    e += 1 + 23;
    e += 1 + 35;
    e += 1 + 35;
    e += 1 + ProtoBufRuntime._sz_enum(encode_EngagementState(r.engagementState));
    e += 1 + ProtoBufRuntime._sz_lendelim(r.customProperties.length);
    return e;
  }

  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.engagementId = input.engagementId;
    output.takerAddress = input.takerAddress;
    output.engagementCreation = input.engagementCreation;
    output.engagementDue = input.engagementDue;
    output.engagementState = input.engagementState;
    output.customProperties = input.customProperties;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library EngagementData