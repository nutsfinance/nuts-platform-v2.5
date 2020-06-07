// source: Payables.proto
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
goog.exportSymbol('proto.Payable', null, global);
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
proto.Payable = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, null);
};
goog.inherits(proto.Payable, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  /**
   * @public
   * @override
   */
  proto.Payable.displayName = 'proto.Payable';
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
proto.Payable.prototype.toObject = function(opt_includeInstance) {
  return proto.Payable.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Deprecated. Whether to include
 *     the JSPB instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.Payable} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.Payable.toObject = function(includeInstance, msg) {
  var f, obj = {
    payableid: (f = msg.getPayableid()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    engagementid: (f = msg.getEngagementid()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    obligatoraddress: (f = msg.getObligatoraddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    claimoraddress: (f = msg.getClaimoraddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    tokenaddress: (f = msg.getTokenaddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    amount: (f = msg.getAmount()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    payableduetimestamp: (f = msg.getPayableduetimestamp()) && SolidityTypes_pb.uint256.toObject(includeInstance, f)
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
 * @return {!proto.Payable}
 */
proto.Payable.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.Payable;
  return proto.Payable.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.Payable} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.Payable}
 */
proto.Payable.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setPayableid(value);
      break;
    case 2:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setEngagementid(value);
      break;
    case 3:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setObligatoraddress(value);
      break;
    case 4:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setClaimoraddress(value);
      break;
    case 5:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setTokenaddress(value);
      break;
    case 6:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setAmount(value);
      break;
    case 7:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setPayableduetimestamp(value);
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
proto.Payable.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.Payable.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.Payable} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.Payable.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getPayableid();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getEngagementid();
  if (f != null) {
    writer.writeMessage(
      2,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getObligatoraddress();
  if (f != null) {
    writer.writeMessage(
      3,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getClaimoraddress();
  if (f != null) {
    writer.writeMessage(
      4,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getTokenaddress();
  if (f != null) {
    writer.writeMessage(
      5,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getAmount();
  if (f != null) {
    writer.writeMessage(
      6,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getPayableduetimestamp();
  if (f != null) {
    writer.writeMessage(
      7,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
};


/**
 * optional solidity.uint256 payableId = 1;
 * @return {?proto.solidity.uint256}
 */
proto.Payable.prototype.getPayableid = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 1));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.Payable.prototype.setPayableid = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearPayableid = function() {
  this.setPayableid(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasPayableid = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional solidity.uint256 engagementId = 2;
 * @return {?proto.solidity.uint256}
 */
proto.Payable.prototype.getEngagementid = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 2));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.Payable.prototype.setEngagementid = function(value) {
  jspb.Message.setWrapperField(this, 2, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearEngagementid = function() {
  this.setEngagementid(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasEngagementid = function() {
  return jspb.Message.getField(this, 2) != null;
};


/**
 * optional solidity.address obligatorAddress = 3;
 * @return {?proto.solidity.address}
 */
proto.Payable.prototype.getObligatoraddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 3));
};


/** @param {?proto.solidity.address|undefined} value */
proto.Payable.prototype.setObligatoraddress = function(value) {
  jspb.Message.setWrapperField(this, 3, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearObligatoraddress = function() {
  this.setObligatoraddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasObligatoraddress = function() {
  return jspb.Message.getField(this, 3) != null;
};


/**
 * optional solidity.address claimorAddress = 4;
 * @return {?proto.solidity.address}
 */
proto.Payable.prototype.getClaimoraddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 4));
};


/** @param {?proto.solidity.address|undefined} value */
proto.Payable.prototype.setClaimoraddress = function(value) {
  jspb.Message.setWrapperField(this, 4, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearClaimoraddress = function() {
  this.setClaimoraddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasClaimoraddress = function() {
  return jspb.Message.getField(this, 4) != null;
};


/**
 * optional solidity.address tokenAddress = 5;
 * @return {?proto.solidity.address}
 */
proto.Payable.prototype.getTokenaddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 5));
};


/** @param {?proto.solidity.address|undefined} value */
proto.Payable.prototype.setTokenaddress = function(value) {
  jspb.Message.setWrapperField(this, 5, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearTokenaddress = function() {
  this.setTokenaddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasTokenaddress = function() {
  return jspb.Message.getField(this, 5) != null;
};


/**
 * optional solidity.uint256 amount = 6;
 * @return {?proto.solidity.uint256}
 */
proto.Payable.prototype.getAmount = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 6));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.Payable.prototype.setAmount = function(value) {
  jspb.Message.setWrapperField(this, 6, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearAmount = function() {
  this.setAmount(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasAmount = function() {
  return jspb.Message.getField(this, 6) != null;
};


/**
 * optional solidity.uint256 payableDueTimestamp = 7;
 * @return {?proto.solidity.uint256}
 */
proto.Payable.prototype.getPayableduetimestamp = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 7));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.Payable.prototype.setPayableduetimestamp = function(value) {
  jspb.Message.setWrapperField(this, 7, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.Payable.prototype.clearPayableduetimestamp = function() {
  this.setPayableduetimestamp(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.Payable.prototype.hasPayableduetimestamp = function() {
  return jspb.Message.getField(this, 7) != null;
};


goog.object.extend(exports, proto);
