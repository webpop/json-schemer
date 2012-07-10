class JsonErrors
  constructor: ->
    @base = []
    @attr = {}
  
  add: (property, error) ->
    if not error?
      error = property
      property = null

    return unless error
    
    if property
      if error instanceof JsonErrors then @_mergeErrors(property, error) else @_addError(property, error)
    else
      @base.push error
    this

  addToBase: (error) -> @add(error)

  on: (property) -> if property then @attr[property] else @base
  onBase: -> @on()
  
  all: ->
    base = if @base.length then [["", @base]] else []
    base.concat([key, err] for key, err of @attr)

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


class JsonProperty
  constructor: (@attr) ->

  cast: (val) -> val

  errors: (val) ->
    errors = new JsonErrors
    errors.add("required") unless @validate "required", (r) -> !(r && typeof(val) == "undefined")
    errors

  process: (val) ->
    val    = if val? then @cast(val) else @attr.default
    errors = @errors(val)
    
    valid: errors.isEmpty()
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
      errors.add("minLength") unless @validate "minLength", (len)  -> val.length >= len
      errors.add("maxLength") unless @validate "maxLength", (len)  -> val.length <= len
      errors.add("pattern")   unless @validate "pattern",   (pat)  -> new RegExp(pat).test(val)
      errors.add("enum")      unless @validate "enum",      (opts) -> val in opts
      errors.add("format")    unless @validate "format",    (format) -> @validFormat(format, val)
    errors

  validFormat: (format, val) ->
    switch @attr.format
      when "date"
        /^\d\d\d\d-\d\d-\d\d$/.test(val)
      when "date-time"
        /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(val)
      else
        true


class JsonNumber extends JsonProperty
  cast: (val) ->
    val = parseFloat(val)
    if isNaN(val) then null else val

  errors: (val) ->
    errors = super(val)
    if val?
      errors.add("minimum")     unless @validate "minimum", (min) -> if @attr.excludeMinimum then val > min else val >= min
      errors.add("maximum")     unless @validate "maximum", (max) -> if @attr.excludeMaximum then val < max else val <= max
      errors.add("divisibleBy") unless @validate "divisibleBy", (div) -> val % div == 0
    errors


class JsonInteger extends JsonNumber
  cast: (val) -> 
    val = parseInt(val, 10)
    if isNaN(val) then null else val


class JsonArray extends JsonProperty
  constructor: (@attr) ->
    if @attr.items
      ref = @attr.items["$ref"]
      @itemSchema = if ref then JsonSchema.resolver(@attr.items["$ref"], this) else JsonProperty.for(@attr.items)

  cast: (val) ->
    cast = if @itemSchema then (v) => @itemSchema.cast(v) else (v) -> v
    cast(item) for item in val

  errors: (val) ->
    errors = super(val)
    if val?
      errors.add("minItems") unless @validate "minItems", (min) -> val.length >= min
      errors.add("maxItems") unless @validate "maxItems", (max) -> val.length <= max
      if @itemSchema
        errors.add("#{i}", @itemSchema.errors(item)) for item, i in val
    errors


class JsonObject extends JsonProperty
  constructor: (@attr) ->
    @properties = attr.properties
    if @properties["$ref"]
      @ref = JsonSchema.resolver(@properties["$ref"].replace(/#.+$/, ''), this)
  
  cast: (val) ->
    return @ref.cast(val) if @ref

    obj = {}
    for key, attrs of @properties
      obj[key] = if val && (key of val) then JsonProperty.for(attrs).cast(val[key]) else attrs.default
    obj

  process: (val) ->
    if @ref then @ref.process(val) else super(val)
  
  errors: (val) ->
    return super(val) unless val?
    return @ref.errors(val) if @ref
    
    errors = super(val)
    
    for key, attrs of @properties
      err = JsonProperty.for(attrs).errors(val && val[key])
      errors.add(key, err)
    errors


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


JsonSchema.resolver = (url, current) ->
  # Override to resolve references
  throw "No resolver defined for references" unless JsonSchema.resolver


e = (exports? && exports) || (window? && window)
e.JsonSchema = JsonSchema
e.JsonErrors = JsonErrors