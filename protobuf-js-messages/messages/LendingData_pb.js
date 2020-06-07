// source: LendingData.proto
/**
 * @fileoverview
 * @enhanceable
 * @suppress {messageConventions} JS Compiler reports an error if a variable or
 *     field starts with 'MSG_' and isn't a translatable message.
 * @public
 */
// GENERATED CODE -- DO NOT EDIT!

var jspb = require('google-protobuf');
var goog = jspb;
var global = Function('return this')();

var SolidityTypes_pb = require('./SolidityTypes_pb.js');
goog.object.extend(proto, SolidityTypes_pb);
goog.exportSymbol('proto.LendingEngagementProperty', null, global);
goog.exportSymbol('proto.LendingEngagementProperty.LoanState', null, global);
goog.exportSymbol('proto.LendingIssuanceProperty', null, global);
/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.LendingIssuanceProperty = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, null);
};
goog.inherits(proto.LendingIssuanceProperty, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  /**
   * @public
   * @override
   */
  proto.LendingIssuanceProperty.displayName = 'proto.LendingIssuanceProperty';
}
/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.LendingEngagementProperty = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, null);
};
goog.inherits(proto.LendingEngagementProperty, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  /**
   * @public
   * @override
   */
  proto.LendingEngagementProperty.displayName = 'proto.LendingEngagementProperty';
}



if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * Optional fields that are not set will be set to undefined.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     net/proto2/compiler/js/internal/generator.cc#kKeyword.
 * @param {boolean=} opt_includeInstance Deprecated. whether to include the
 *     JSPB instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @return {!Object}
 */
proto.LendingIssuanceProperty.prototype.toObject = function(opt_includeInstance) {
  return proto.LendingIssuanceProperty.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Deprecated. Whether to include
 *     the JSPB instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.LendingIssuanceProperty} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.LendingIssuanceProperty.toObject = function(includeInstance, msg) {
  var f, obj = {
    lendingtokenaddress: (f = msg.getLendingtokenaddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    collateraltokenaddress: (f = msg.getCollateraltokenaddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    lendingamount: (f = msg.getLendingamount()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    collateralratio: (f = msg.getCollateralratio()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    interestrate: (f = msg.getInterestrate()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    interestamount: (f = msg.getInterestamount()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    tenordays: (f = msg.getTenordays()) && SolidityTypes_pb.uint256.toObject(includeInstance, f)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.LendingIssuanceProperty}
 */
proto.LendingIssuanceProperty.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.LendingIssuanceProperty;
  return proto.LendingIssuanceProperty.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.LendingIssuanceProperty} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.LendingIssuanceProperty}
 */
proto.LendingIssuanceProperty.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setLendingtokenaddress(value);
      break;
    case 2:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setCollateraltokenaddress(value);
      break;
    case 3:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setLendingamount(value);
      break;
    case 4:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setCollateralratio(value);
      break;
    case 5:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setInterestrate(value);
      break;
    case 6:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setInterestamount(value);
      break;
    case 7:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setTenordays(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.LendingIssuanceProperty.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.LendingIssuanceProperty.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.LendingIssuanceProperty} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.LendingIssuanceProperty.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getLendingtokenaddress();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getCollateraltokenaddress();
  if (f != null) {
    writer.writeMessage(
      2,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getLendingamount();
  if (f != null) {
    writer.writeMessage(
      3,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getCollateralratio();
  if (f != null) {
    writer.writeMessage(
      4,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getInterestrate();
  if (f != null) {
    writer.writeMessage(
      5,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getInterestamount();
  if (f != null) {
    writer.writeMessage(
      6,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getTenordays();
  if (f != null) {
    writer.writeMessage(
      7,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
};


/**
 * optional solidity.address lendingTokenAddress = 1;
 * @return {?proto.solidity.address}
 */
proto.LendingIssuanceProperty.prototype.getLendingtokenaddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 1));
};


/** @param {?proto.solidity.address|undefined} value */
proto.LendingIssuanceProperty.prototype.setLendingtokenaddress = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearLendingtokenaddress = function() {
  this.setLendingtokenaddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasLendingtokenaddress = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional solidity.address collateralTokenAddress = 2;
 * @return {?proto.solidity.address}
 */
proto.LendingIssuanceProperty.prototype.getCollateraltokenaddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 2));
};


/** @param {?proto.solidity.address|undefined} value */
proto.LendingIssuanceProperty.prototype.setCollateraltokenaddress = function(value) {
  jspb.Message.setWrapperField(this, 2, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearCollateraltokenaddress = function() {
  this.setCollateraltokenaddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasCollateraltokenaddress = function() {
  return jspb.Message.getField(this, 2) != null;
};


/**
 * optional solidity.uint256 lendingAmount = 3;
 * @return {?proto.solidity.uint256}
 */
proto.LendingIssuanceProperty.prototype.getLendingamount = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 3));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.LendingIssuanceProperty.prototype.setLendingamount = function(value) {
  jspb.Message.setWrapperField(this, 3, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearLendingamount = function() {
  this.setLendingamount(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasLendingamount = function() {
  return jspb.Message.getField(this, 3) != null;
};


/**
 * optional solidity.uint256 collateralRatio = 4;
 * @return {?proto.solidity.uint256}
 */
proto.LendingIssuanceProperty.prototype.getCollateralratio = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 4));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.LendingIssuanceProperty.prototype.setCollateralratio = function(value) {
  jspb.Message.setWrapperField(this, 4, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearCollateralratio = function() {
  this.setCollateralratio(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasCollateralratio = function() {
  return jspb.Message.getField(this, 4) != null;
};


/**
 * optional solidity.uint256 interestRate = 5;
 * @return {?proto.solidity.uint256}
 */
proto.LendingIssuanceProperty.prototype.getInterestrate = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 5));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.LendingIssuanceProperty.prototype.setInterestrate = function(value) {
  jspb.Message.setWrapperField(this, 5, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearInterestrate = function() {
  this.setInterestrate(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasInterestrate = function() {
  return jspb.Message.getField(this, 5) != null;
};


/**
 * optional solidity.uint256 interestAmount = 6;
 * @return {?proto.solidity.uint256}
 */
proto.LendingIssuanceProperty.prototype.getInterestamount = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 6));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.LendingIssuanceProperty.prototype.setInterestamount = function(value) {
  jspb.Message.setWrapperField(this, 6, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearInterestamount = function() {
  this.setInterestamount(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasInterestamount = function() {
  return jspb.Message.getField(this, 6) != null;
};


/**
 * optional solidity.uint256 tenorDays = 7;
 * @return {?proto.solidity.uint256}
 */
proto.LendingIssuanceProperty.prototype.getTenordays = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 7));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.LendingIssuanceProperty.prototype.setTenordays = function(value) {
  jspb.Message.setWrapperField(this, 7, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingIssuanceProperty.prototype.clearTenordays = function() {
  this.setTenordays(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingIssuanceProperty.prototype.hasTenordays = function() {
  return jspb.Message.getField(this, 7) != null;
};





if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * Optional fields that are not set will be set to undefined.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     net/proto2/compiler/js/internal/generator.cc#kKeyword.
 * @param {boolean=} opt_includeInstance Deprecated. whether to include the
 *     JSPB instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @return {!Object}
 */
proto.LendingEngagementProperty.prototype.toObject = function(opt_includeInstance) {
  return proto.LendingEngagementProperty.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Deprecated. Whether to include
 *     the JSPB instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.LendingEngagementProperty} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.LendingEngagementProperty.toObject = function(includeInstance, msg) {
  var f, obj = {
    collateralamount: (f = msg.getCollateralamount()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    loanstate: jspb.Message.getFieldWithDefault(msg, 2, 0)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.LendingEngagementProperty}
 */
proto.LendingEngagementProperty.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.LendingEngagementProperty;
  return proto.LendingEngagementProperty.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.LendingEngagementProperty} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.LendingEngagementProperty}
 */
proto.LendingEngagementProperty.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setCollateralamount(value);
      break;
    case 2:
      var value = /** @type {!proto.LendingEngagementProperty.LoanState} */ (reader.readEnum());
      msg.setLoanstate(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.LendingEngagementProperty.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.LendingEngagementProperty.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.LendingEngagementProperty} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.LendingEngagementProperty.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getCollateralamount();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getLoanstate();
  if (f !== 0.0) {
    writer.writeEnum(
      2,
      f
    );
  }
};


/**
 * @enum {number}
 */
proto.LendingEngagementProperty.LoanState = {
  LOANSTATEUNKNOWN: 0,
  UNPAID: 1,
  REPAID: 2,
  DELINQUENT: 3
};

/**
 * optional solidity.uint256 collateralAmount = 1;
 * @return {?proto.solidity.uint256}
 */
proto.LendingEngagementProperty.prototype.getCollateralamount = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 1));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.LendingEngagementProperty.prototype.setCollateralamount = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.LendingEngagementProperty.prototype.clearCollateralamount = function() {
  this.setCollateralamount(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.LendingEngagementProperty.prototype.hasCollateralamount = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional LoanState loanState = 2;
 * @return {!proto.LendingEngagementProperty.LoanState}
 */
proto.LendingEngagementProperty.prototype.getLoanstate = function() {
  return /** @type {!proto.LendingEngagementProperty.LoanState} */ (jspb.Message.getFieldWithDefault(this, 2, 0));
};


/** @param {!proto.LendingEngagementProperty.LoanState} value */
proto.LendingEngagementProperty.prototype.setLoanstate = function(value) {
  jspb.Message.setProto3EnumField(this, 2, value);
};


goog.object.extend(exports, proto);
