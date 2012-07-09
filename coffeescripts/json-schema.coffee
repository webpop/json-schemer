class JsonProperty
  constructor: (@attr) ->

  cast: (val) -> val

  errors: (val) ->
    errors = []
    errors.push("required") unless @validate "required", (r) -> !(r && typeof(val) == "undefined")
    errors

  process: (val) ->
    val        = if val? then @cast(val) else val
    errors = @errors(val)
    
    valid: errors.length == 0
    value: val
    errors: errors
  
  validate: (attr, fn) -> if (attr of @attr) then fn.call(this, @attr[attr]) else true


class JsonString extends JsonProperty
  cast: (val) ->
    switch @attr.format
      when "date", "date-time"
        new Date(val)
      else
        val.toString()

  errors: (val) ->
    errors = super(val)
    if val?
      errors.push("minLength") unless @validate "minLength", (len)  -> val.length >= len
      errors.push("maxLength") unless @validate "maxLength", (len)  -> val.length <= len
      errors.push("pattern")   unless @validate "pattern",   (pat)  -> new RegExp(pat).test(val)
      errors.push("enum")      unless @validate "enum",      (opts) -> val in opts
      errors.push("format")    unless @validate "format",    (format) -> @validFormat(format, val)
    errors

  validFormat: (format, val) ->
    switch @attr.format
      when "date"
        /^\d\d\d\d-\d\d-\d\d$/.test(val)
      when "date-time"
        /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(val)
      else
        truen

class JsonNumber extends JsonProperty
  cast: (val) ->
    val = parseFloat(val)
    if isNaN(val) then null else val

  errors: (val) ->
    errors = super(val)
    if val?
      errors.push("minimum")     unless @validate "minimum", (min) -> if @attr.excludeMinimum then val > min else val >= min
      errors.push("maximum")     unless @validate "maximum", (max) -> if @attr.excludeMaximum then val < max else val <= max
      errors.push("divisibleBy") unless @validate "divisibleBy", (div) -> val % div == 0
    errors


class JsonInteger extends JsonNumber
  cast: (val) -> 
    val = parseInt(val, 10)
    if isNaN(val) then null else val


class JsonArray extends JsonProperty
  constructor: (@attr) ->
    @itemSchema = @attr.items && JsonProperty.for(@attr.items)

  cast: (val) ->
    cast = if @itemSchema then (v) => @itemSchema.cast(v) else (v) -> v
    cast(item) for item in val

  errors: (val) ->
    errors = super(val)
    if val?
      errors.push("minItems") unless @validate "minItems", (min) -> val.length >= min
      errors.push("maxItems") unless @validate "maxItems", (max) -> val.length <= max
      errors = errors.concat(@itemErrors(val)) if @itemSchema
    errors

  itemErrors: (val) ->
    valueErrors = {}
    for item in val
      for err in @itemSchema.errors(item)
        valueErrors[err] = true
    Object.keys(valueErrors)


class JsonObject extends JsonProperty
  constructor: (@attr) ->
    @properties = attr.properties

  process: (obj) ->
    ret = {valid: true, errors: {}, value: {}}
    for key, attrs of @properties
      prop = JsonProperty.for(attrs).process(obj[key])
      ret.value[key] = prop.value
      ret.valid = ret.valid && prop.valid
      ret.errors[key] = prop.errors unless prop.valid
    ret


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


class JsonSchema extends JsonObject



if exports?
  exports.JsonSchema = JsonSchema
else if window?
  window.JsonSchema  = JsonSchema