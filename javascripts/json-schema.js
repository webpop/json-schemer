// Generated by CoffeeScript 1.3.3
(function() {
  var JsonArray, JsonInteger, JsonNumber, JsonObject, JsonProperty, JsonSchema, JsonString,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  JsonProperty = (function() {

    function JsonProperty(attr) {
      this.attr = attr;
    }

    JsonProperty.prototype.cast = function(val) {
      return val;
    };

    JsonProperty.prototype.errors = function(val) {
      var errors;
      errors = [];
      if (!this.validate("required", function(r) {
        return !(r && typeof val === "undefined");
      })) {
        errors.push("required");
      }
      return errors;
    };

    JsonProperty.prototype.process = function(val) {
      var errors;
      val = val != null ? this.cast(val) : val;
      errors = this.errors(val);
      return {
        valid: errors.length === 0,
        value: val,
        errors: errors
      };
    };

    JsonProperty.prototype.validate = function(attr, fn) {
      if (attr in this.attr) {
        return fn.call(this, this.attr[attr]);
      } else {
        return true;
      }
    };

    return JsonProperty;

  })();

  JsonString = (function(_super) {

    __extends(JsonString, _super);

    function JsonString() {
      return JsonString.__super__.constructor.apply(this, arguments);
    }

    JsonString.prototype.cast = function(val) {
      switch (this.attr.format) {
        case "date":
        case "date-time":
          return new Date(val);
        default:
          return val.toString();
      }
    };

    JsonString.prototype.errors = function(val) {
      var errors;
      errors = JsonString.__super__.errors.call(this, val);
      if (val != null) {
        if (!this.validate("minLength", function(len) {
          return val.length >= len;
        })) {
          errors.push("minLength");
        }
        if (!this.validate("maxLength", function(len) {
          return val.length <= len;
        })) {
          errors.push("maxLength");
        }
        if (!this.validate("pattern", function(pat) {
          return new RegExp(pat).test(val);
        })) {
          errors.push("pattern");
        }
        if (!this.validate("enum", function(opts) {
          return __indexOf.call(opts, val) >= 0;
        })) {
          errors.push("enum");
        }
        if (!this.validate("format", function(format) {
          return this.validFormat(format, val);
        })) {
          errors.push("format");
        }
      }
      return errors;
    };

    JsonString.prototype.validFormat = function(format, val) {
      switch (this.attr.format) {
        case "date":
          return /^\d\d\d\d-\d\d-\d\d$/.test(val);
        case "date-time":
          return /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(val);
        default:
          return truen;
      }
    };

    return JsonString;

  })(JsonProperty);

  JsonNumber = (function(_super) {

    __extends(JsonNumber, _super);

    function JsonNumber() {
      return JsonNumber.__super__.constructor.apply(this, arguments);
    }

    JsonNumber.prototype.cast = function(val) {
      val = parseFloat(val);
      if (isNaN(val)) {
        return null;
      } else {
        return val;
      }
    };

    JsonNumber.prototype.errors = function(val) {
      var errors;
      errors = JsonNumber.__super__.errors.call(this, val);
      if (val != null) {
        if (!this.validate("minimum", function(min) {
          if (this.attr.excludeMinimum) {
            return val > min;
          } else {
            return val >= min;
          }
        })) {
          errors.push("minimum");
        }
        if (!this.validate("maximum", function(max) {
          if (this.attr.excludeMaximum) {
            return val < max;
          } else {
            return val <= max;
          }
        })) {
          errors.push("maximum");
        }
        if (!this.validate("divisibleBy", function(div) {
          return val % div === 0;
        })) {
          errors.push("divisibleBy");
        }
      }
      return errors;
    };

    return JsonNumber;

  })(JsonProperty);

  JsonInteger = (function(_super) {

    __extends(JsonInteger, _super);

    function JsonInteger() {
      return JsonInteger.__super__.constructor.apply(this, arguments);
    }

    JsonInteger.prototype.cast = function(val) {
      val = parseInt(val, 10);
      if (isNaN(val)) {
        return null;
      } else {
        return val;
      }
    };

    return JsonInteger;

  })(JsonNumber);

  JsonArray = (function(_super) {

    __extends(JsonArray, _super);

    function JsonArray(attr) {
      this.attr = attr;
      this.itemSchema = this.attr.items && JsonProperty["for"](this.attr.items);
    }

    JsonArray.prototype.cast = function(val) {
      var cast, item, _i, _len, _results,
        _this = this;
      cast = this.itemSchema ? function(v) {
        return _this.itemSchema.cast(v);
      } : function(v) {
        return v;
      };
      _results = [];
      for (_i = 0, _len = val.length; _i < _len; _i++) {
        item = val[_i];
        _results.push(cast(item));
      }
      return _results;
    };

    JsonArray.prototype.errors = function(val) {
      var errors;
      errors = JsonArray.__super__.errors.call(this, val);
      if (val != null) {
        if (!this.validate("minItems", function(min) {
          return val.length >= min;
        })) {
          errors.push("minItems");
        }
        if (!this.validate("maxItems", function(max) {
          return val.length <= max;
        })) {
          errors.push("maxItems");
        }
        if (this.itemSchema) {
          errors = errors.concat(this.itemErrors(val));
        }
      }
      return errors;
    };

    JsonArray.prototype.itemErrors = function(val) {
      var err, item, valueErrors, _i, _j, _len, _len1, _ref;
      valueErrors = {};
      for (_i = 0, _len = val.length; _i < _len; _i++) {
        item = val[_i];
        _ref = this.itemSchema.errors(item);
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          err = _ref[_j];
          valueErrors[err] = true;
        }
      }
      return Object.keys(valueErrors);
    };

    return JsonArray;

  })(JsonProperty);

  JsonObject = (function(_super) {

    __extends(JsonObject, _super);

    function JsonObject(attr) {
      this.attr = attr;
      this.properties = attr.properties;
    }

    JsonObject.prototype.process = function(obj) {
      var attrs, key, prop, ret, _ref;
      ret = {
        valid: true,
        errors: {},
        value: {}
      };
      _ref = this.properties;
      for (key in _ref) {
        attrs = _ref[key];
        prop = JsonProperty["for"](attrs).process(obj[key]);
        ret.value[key] = prop.value;
        ret.valid = ret.valid && prop.valid;
        if (!prop.valid) {
          ret.errors[key] = prop.errors;
        }
      }
      return ret;
    };

    return JsonObject;

  })(JsonProperty);

  JsonProperty["for"] = function(attr) {
    var klass, type;
    type = attr.type || "any";
    klass = {
      "any": JsonProperty,
      "string": JsonString,
      "number": JsonNumber,
      "integer": JsonInteger,
      "array": JsonArray,
      "object": JsonObject
    }[type];
    if (!klass) {
      throw "Bad Schema - Unknown property type " + type;
    }
    return new klass(attr);
  };

  JsonSchema = (function(_super) {

    __extends(JsonSchema, _super);

    function JsonSchema() {
      return JsonSchema.__super__.constructor.apply(this, arguments);
    }

    return JsonSchema;

  })(JsonObject);

  if (typeof exports !== "undefined" && exports !== null) {
    exports.JsonSchema = JsonSchema;
  } else if (typeof window !== "undefined" && window !== null) {
    window.JsonSchema = JsonSchema;
  }

}).call(this);
