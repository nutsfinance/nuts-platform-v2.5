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
goog.exportSymbol('proto.SwapIssuanceProperty', null, global);
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
proto.SwapIssuanceProperty = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, null);
};
goog.inherits(proto.SwapIssuanceProperty, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  /**
   * @public
   * @override
   */
  proto.SwapIssuanceProperty.displayName = 'proto.SwapIssuanceProperty';
}



if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto suitable for use in Soy templates.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     com.google.apps.jspb.JsClassTemplate.JS_RESERVED_WORDS.
 * @param {boolean=} opt_includeInstance Whether to include the JSPB instance
 *     for transitional soy proto support: http://goto/soy-param-migration
 * @return {!Object}
 */
proto.SwapIssuanceProperty.prototype.toObject = function(opt_includeInstance) {
  return proto.SwapIssuanceProperty.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Whether to include the JSPB
 *     instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.SwapIssuanceProperty} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.SwapIssuanceProperty.toObject = function(includeInstance, msg) {
  var f, obj = {
    inputtokenaddress: (f = msg.getInputtokenaddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    outputtokenaddress: (f = msg.getOutputtokenaddress()) && SolidityTypes_pb.address.toObject(includeInstance, f),
    inputamount: (f = msg.getInputamount()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    outputamount: (f = msg.getOutputamount()) && SolidityTypes_pb.uint256.toObject(includeInstance, f),
    duration: (f = msg.getDuration()) && SolidityTypes_pb.uint256.toObject(includeInstance, f)
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
 * @return {!proto.SwapIssuanceProperty}
 */
proto.SwapIssuanceProperty.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.SwapIssuanceProperty;
  return proto.SwapIssuanceProperty.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.SwapIssuanceProperty} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.SwapIssuanceProperty}
 */
proto.SwapIssuanceProperty.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setInputtokenaddress(value);
      break;
    case 2:
      var value = new SolidityTypes_pb.address;
      reader.readMessage(value,SolidityTypes_pb.address.deserializeBinaryFromReader);
      msg.setOutputtokenaddress(value);
      break;
    case 3:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setInputamount(value);
      break;
    case 4:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setOutputamount(value);
      break;
    case 5:
      var value = new SolidityTypes_pb.uint256;
      reader.readMessage(value,SolidityTypes_pb.uint256.deserializeBinaryFromReader);
      msg.setDuration(value);
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
proto.SwapIssuanceProperty.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.SwapIssuanceProperty.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.SwapIssuanceProperty} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.SwapIssuanceProperty.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getInputtokenaddress();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getOutputtokenaddress();
  if (f != null) {
    writer.writeMessage(
      2,
      f,
      SolidityTypes_pb.address.serializeBinaryToWriter
    );
  }
  f = message.getInputamount();
  if (f != null) {
    writer.writeMessage(
      3,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getOutputamount();
  if (f != null) {
    writer.writeMessage(
      4,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
  f = message.getDuration();
  if (f != null) {
    writer.writeMessage(
      5,
      f,
      SolidityTypes_pb.uint256.serializeBinaryToWriter
    );
  }
};


/**
 * optional solidity.address inputTokenAddress = 1;
 * @return {?proto.solidity.address}
 */
proto.SwapIssuanceProperty.prototype.getInputtokenaddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 1));
};


/** @param {?proto.solidity.address|undefined} value */
proto.SwapIssuanceProperty.prototype.setInputtokenaddress = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.SwapIssuanceProperty.prototype.clearInputtokenaddress = function() {
  this.setInputtokenaddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.SwapIssuanceProperty.prototype.hasInputtokenaddress = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional solidity.address outputTokenAddress = 2;
 * @return {?proto.solidity.address}
 */
proto.SwapIssuanceProperty.prototype.getOutputtokenaddress = function() {
  return /** @type{?proto.solidity.address} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.address, 2));
};


/** @param {?proto.solidity.address|undefined} value */
proto.SwapIssuanceProperty.prototype.setOutputtokenaddress = function(value) {
  jspb.Message.setWrapperField(this, 2, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.SwapIssuanceProperty.prototype.clearOutputtokenaddress = function() {
  this.setOutputtokenaddress(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.SwapIssuanceProperty.prototype.hasOutputtokenaddress = function() {
  return jspb.Message.getField(this, 2) != null;
};


/**
 * optional solidity.uint256 inputAmount = 3;
 * @return {?proto.solidity.uint256}
 */
proto.SwapIssuanceProperty.prototype.getInputamount = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 3));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.SwapIssuanceProperty.prototype.setInputamount = function(value) {
  jspb.Message.setWrapperField(this, 3, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.SwapIssuanceProperty.prototype.clearInputamount = function() {
  this.setInputamount(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.SwapIssuanceProperty.prototype.hasInputamount = function() {
  return jspb.Message.getField(this, 3) != null;
};


/**
 * optional solidity.uint256 outputAmount = 4;
 * @return {?proto.solidity.uint256}
 */
proto.SwapIssuanceProperty.prototype.getOutputamount = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 4));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.SwapIssuanceProperty.prototype.setOutputamount = function(value) {
  jspb.Message.setWrapperField(this, 4, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.SwapIssuanceProperty.prototype.clearOutputamount = function() {
  this.setOutputamount(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.SwapIssuanceProperty.prototype.hasOutputamount = function() {
  return jspb.Message.getField(this, 4) != null;
};


/**
 * optional solidity.uint256 duration = 5;
 * @return {?proto.solidity.uint256}
 */
proto.SwapIssuanceProperty.prototype.getDuration = function() {
  return /** @type{?proto.solidity.uint256} */ (
    jspb.Message.getWrapperField(this, SolidityTypes_pb.uint256, 5));
};


/** @param {?proto.solidity.uint256|undefined} value */
proto.SwapIssuanceProperty.prototype.setDuration = function(value) {
  jspb.Message.setWrapperField(this, 5, value);
};


/**
 * Clears the message field making it undefined.
 */
proto.SwapIssuanceProperty.prototype.clearDuration = function() {
  this.setDuration(undefined);
};


/**
 * Returns whether this field is set.
 * @return {boolean}
 */
proto.SwapIssuanceProperty.prototype.hasDuration = function() {
  return jspb.Message.getField(this, 5) != null;
};


goog.object.extend(exports, proto);
