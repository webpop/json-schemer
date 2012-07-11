# is a json-schema validator with a twist: instead of just validating json documents,
# it will also cast the values of a document to fit a schema.
#
# This is very handy if you need to process form submissions where all data comes
# in form of strings.

#### Usage
# To process a schema:
#
#     schema = new JsonSchema
#       type: "object"
#         properties:
#           name:
#             type: "string"
#             required: true
#           age:
#             type: "integer"
#     
#     result = schema.process({name: "Mathias", age: "35"})
#     result.valid == true
#     result.doc   == {name: "Mathias", age: 35}
#     result.errors.isEmpty() == true
# 
#     result = schema.process({title: "Bad Doc"})
#     result.valid == false
#     result.doc   == {}
#     result.errors.on("name") == ["required"]

#### JsonErrors

class JsonErrors
  constructor: ->
    @base = []
    @attr = {}
  
  # Add an error to a property.
  # If the error is another JsonErrors object the errors from
  # that object will be merged into the current error object.
  add: (property, error) ->
    return unless property || error

    if not error?
      error = property
      property = null
    
    if property
      if error instanceof JsonErrors then @_mergeErrors(property, error) else @_addError(property, error)
    else
      @base.push error
  
  # Add an error with no property associated
  addToBase: (error) -> @add(error)

  # Get any errors on a property. Returns an array of errors
  on: (property) -> if property then @attr[property] else @base

  # Get any errors on the base property. Returns and array of errors.
  onBase: -> @on()

  # Returns an array of all errors: [[property, [errors]]]
  all: ->
    base = if @base.length then [["", @base]] else []
    base.concat([key, err] for key, err of @attr)

  # Return true if no errors have been added
  isEmpty: -> @base.length == 0 && Object.keys(@attr).length == 0

  _addError: (property, error) ->
    @attr[property] ||= []
    if error.length
      @attr[property] = @attr[property].concat(error)
    else
      @attr[property].push error
  
  _mergeErrors: (property, errors) ->
    return if errors.isEmpty()
    for [prop, err] in errors.all()
      newProp = if prop then "#{property}.#{prop}" else property
      @add(newProp, err)

#### JsonProperty

# The base class in the JsonSchema hierachy.
class JsonProperty
  constructor: (@attr) ->

  # Case a value to the type specified by this propery
  cast: (val, cb) -> cb(null, val)

  # Return any errors for this property
  errors: (val, cb) ->
    errors = new JsonErrors
    errors.add("required") unless @validate "required", (r) -> !(r && typeof(val) == "undefined")
    cb(null, errors)

  # Process a value. Return an object with the keys valid, doc and errors
  process: (val, cb) ->
    valCb    = if val? then @cast else (val, cb) -> cb(null, @attr.default)
    valCb.call this, val, (err, val) =>
      return cb(err) if err
      
      @errors val, (err, errors) ->
        return cb(err) if err
        cb(null, {
          valid: errors.isEmpty()
          doc: val
          errors: errors          
        })

  # Helper method to perform a validtion if an attribute is present
  validate: (attr, fn) -> if (attr of @attr) and @attr[attr] != null then fn.call(this, @attr[attr]) else true

#### JsonString

# A property of type "string"
class JsonString extends JsonProperty
  cast: (val, cb) ->
    switch @attr.format
      when "date", "date-time"
        cb(null, new Date(val))
      else
        cb(null, val.toString())

  errors: (val, cb) ->
    super val, (err, errors) =>
      return cb(err) if err
      if val?
        errors.add("minLength") unless @validate "minLength", (len)  -> val.length >= len
        errors.add("maxLength") unless @validate "maxLength", (len)  -> val.length <= len
        errors.add("pattern")   unless @validate "pattern",   (pat)  -> new RegExp(pat).test(val)
        errors.add("enum")      unless @validate "enum",      (opts) -> val in opts
        errors.add("format")    unless @validate "format",    (format) -> @validFormat(format, val)
      cb(null, errors)

  validFormat: (format, val) ->
    switch @attr.format
      when "date"
        /^\d\d\d\d-\d\d-\d\d$/.test(val)
      when "date-time"
        /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(val)
      else
        true

#### JsonNumber

# A property of type "number"
class JsonNumber extends JsonProperty
  cast: (val, cb) ->
    val = parseFloat(val)
    cb(null, if isNaN(val) then null else val)

  errors: (val, cb) ->
    super val, (err, errors) =>
      return cb(err) if err
      if val?
        errors.add("minimum")     unless @validate "minimum", (min) -> if @attr.excludeMinimum then val > min else val >= min
        errors.add("maximum")     unless @validate "maximum", (max) -> if @attr.excludeMaximum then val < max else val <= max
        errors.add("divisibleBy") unless @validate "divisibleBy", (div) -> val % div == 0
      cb(null, errors)

#### JsonInteger

# A property of type "integer"
class JsonInteger extends JsonNumber
  cast: (val, cb) -> 
    val = parseInt(val, 10)
    cb(null, if isNaN(val) then null else val)

#### JsonArray

# A property of class "array".
# If the array items are specified with a "$ref" ({items: {"$ref": "uri"}}) the JsonSchema.resolver will
# be used to return a schema object for the items.
class JsonArray extends JsonProperty
  cast: (val, cb) ->
    @itemSchema (err, schema) ->
      console.log("Got itemSchema %o", schema)
      return cb(null, item for item in val) unless schema
      items = []
      count = val.length      
      for item, index in val
        do (item, index) => schema.cast item, (err, itemVal) ->
          if err
            cb(err)
            return cb = ->
          items[index] = itemVal
          if --count == 0 then cb(null, items)

  errors: (val, cb) ->
    super val, (err, errors) =>
      if val?
        errors.add("minItems") unless @validate "minItems", (min) -> val.length >= min
        errors.add("maxItems") unless @validate "maxItems", (max) -> val.length <= max
        @itemSchema (err, schema) =>
          return cb(null, errors) unless schema

          count = val.length
          for item, i in val
            do (item, i) =>
              schema.errors item, (err, itemErrors) ->
                if err
                  cb(err)
                  return cb = ->
                errors.add("#{i}", itemErrors)
                if --count == 0 then cb(null, errors)

  itemSchema: (cb) ->
    return cb(null, null) unless @attr.items
    if @attr.items["$ref"]
      return cb(null, @_itemSchema) if @_itemSchema
      JsonSchema.resolver @attr.items["$ref"], this, (err, schema) =>
        return cb(err) if err
        @_itemSchema = schema
        cb(null, schema)
    else
      cb(null, JsonProperty.for(@attr.items))

#### JsonObject

# A property of type "object".
# If the properties are specified with a "$ref" (properties: {"$ref" : "uri"}) the 
# JsonSchema.resolver will be used to lookup a schema object used for cast, errors
# and process
class JsonObject extends JsonProperty
  constructor: (@attr) ->
    @properties = attr.properties
  
  cast: (val, cb) ->
    @refSchema (err, schema) =>
      return cb(err) if err
      return schema.cast(val, cb) if schema

      obj = {}
      count = Object.keys(@properties).length
      for key, attrs of @properties
        do (key, attrs) =>
          caster = if val && (key of val) then JsonProperty.for(attrs) else {cast: (_, cb) -> cb(null, attrs.default) }
          caster.cast val[key], (err, castedVal) ->
            if err
              cb(err)
              return cb = ->
            obj[key] = castedVal
            if --count == 0 then cb(null, obj)

  process: (val, cb) ->
    @refSchema (err, schema) =>
      return cb(err) if err
      if schema then schema.process(val, cb) else super(val, cb)
  
  errors: (val, cb) ->
    return super(val, cb) unless val?
    @refSchema (err, schema) =>
      return cb(err) if err
      return schema.errors(val, cb) if schema
    
      super val, (err, errors) =>
        return cb(err) if err
        count = Object.keys(@properties).length
        for key, attrs of @properties
          do (key, attrs) =>
            JsonProperty.for(attrs).errors val && val[key], (err, propErrors) ->
              if err
                cb(err)
                return cb = ->
              errors.add(key, propErrors)
              if --count == 0 then cb(null, errors)

  refSchema: (cb) ->
    return cb(null, @_refSchema) if @_refSchema
    if @properties["$ref"]
      JsonSchema.resolver @properties["$ref"].replace(/#.+$/, ''), this, (err, schema) =>
        return cb(err) if err
        @_refSchema = schema
        cb(null, schema)
    else
      cb(null, null)
    
# Factory method for JsonProperties
JsonProperty.for = (attr) ->
  type  = attr.type || "any"  
  klass = {
    "any"     : JsonProperty
    "string"  : JsonString
    "number"  : JsonNumber
    "integer" : JsonInteger
    "array"   : JsonArray
    "object"  : JsonObject
    
  }[type]
  throw "Bad Schema - Unknown property type #{type}" unless klass
  new klass(attr)


#### JsonSchema

# The public interface to the JsonSchema processor.
# Requires the main schema to be of type "object"
class JsonSchema extends JsonObject
  constructor: (attr) ->
    throw "The main schema must be of type \"object\"" unless attr.type == "object"
    super(attr)

#### The JsonSchema.resolver

# This function will be used to resolve any url used in "$ref" references.
# The function should return an object responding to cast, errors and process.
JsonSchema.resolver = (url, schema, cb) ->
  # Override to resolve references
  throw "No resolver defined for references" unless JsonSchema.resolver


# Export public interface
e = (exports? && exports) || (window? && window)
e.JsonSchema = JsonSchema
e.JsonErrors = JsonErrors