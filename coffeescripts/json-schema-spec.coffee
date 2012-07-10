describe "JsonSchema", ->
  describe "with a simple example schema from the ietf draft", ->
    beforeEach ->
      @schema = new JsonSchema
        description: "A person"
        type:"object"
        properties:
          name: {type: "string"}
          age:
            type: "integer"
            maximum: 125

    it "should process an empty object", ->
      result = @schema.process({})
      expect(Object.keys(result.value)).toEqual(['name', 'age'])
      expect(result.value.name).toBe(undefined)
      expect(result.value.age).toBe(undefined)
      expect(result.valid).toBe(true)

    it "should process a valid object", ->
      result = @schema.process({name: "Mathias", age: 35})
      expect(Object.keys(result.value)).toEqual(["name", "age"])
      expect(result.value.name).toEqual("Mathias")
      expect(result.value.age).toEqual(35)
      expect(result.valid).toBe(true)

    it "should cast strings to numbers where needed", ->
      result = @schema.process({age: "35"})
      expect(result.value.age).toEqual(35)
      expect(result.valid).toBe(true)

    it "should validate the maximum for a number", ->
      result = @schema.process({age: 200})
      expect(result.value.age).toEqual(200)
      expect(result.valid).toBe(false)
      expect(result.errors.all()).toEqual([["age", ["maximum"]]])

    it "should use a default value", ->
      @schema.properties.name.default = "Default"
      result = @schema.process({})
      expect(result.value.name).toEqual("Default")

  describe "validations", ->
    describe "optional and required fields", ->
      beforeEach ->
        @schema = new JsonSchema
          type: "object"
          properties:
            optional:
              type: "string"
            required:
              type: "string"
              required: true

      it "should validate required fields", ->
        result = @schema.process({})
        expect(result.valid).toBe(false)
        expect(result.errors.on("optional")).toBe(undefined)
        expect(result.errors.on("required")).toEqual(["required"])

    describe "string validations", ->
      beforeEach ->
        @schema = new JsonSchema
          type: "object"
          properties:
            minlength:
              type: "string"
              minLength: 1
            maxlength:
              type: "string"
              maxLength: 2
            pattern:
              type: "string"
              pattern: "^[a-z]+$"
            enum:
              type: "string"
              enum: ["one", "two", "three"]

      it "should validate the minLength", ->
        result = @schema.process({minlength: ""})
        expect(result.valid).toBe(false)
        expect(result.errors.on("minlength")).toEqual(["minLength"])
        expect(@schema.process({minlength: "good"}).valid).toBe(true)

      it "should validate the maxLength", ->
        result = @schema.process({maxlength: "hello"})
        expect(result.valid).toBe(false)
        expect(result.errors.on("maxlength")).toEqual(["maxLength"])
        expect(@schema.process({maxlength: "It"}).valid).toBe(true)

      it "should validate the pattern", ->
        result = @schema.process({pattern: "Has Spaces"})
        expect(result.valid).toBe(false)
        expect(result.errors.on("pattern")).toEqual(["pattern"])
        expect(@schema.process({pattern: "nospaces"}).valid).toBe(true)

      it "should validate the enum", ->
        result = @schema.process({enum: "four"})
        expect(result.valid).toBe(false)
        expect(result.errors.on("enum")).toEqual(["enum"])
        expect(@schema.process({enum: "two"}).valid).toBe(true)

    describe "date and time", ->
      beforeEach ->
        @schema = new JsonSchema
          type: "object"
          properties:
            datetime:
              type: "string"
              format: "date-time"
            date:
              type: "string"
              format: "date"

      it "should process a date", ->
        result = @schema.process({date: "2012-07-09"})
        expect(result.value.date.getFullYear()).toEqual(2012)

      it "should process a date-time", ->
        result = @schema.process({datetime: "2012-07-09T12:09:18Z"})
        expect(result.value.datetime.getFullYear()).toEqual(2012)

      it "should validate a date", ->
        result = @schema.process({date: "09/09/2012"})
        expect(result.valid).toBe(false)
        expect(result.errors.on("date")).toEqual(["format"])

    describe "number validations", ->
      beforeEach ->
        @schema = new JsonSchema
          type: "object"
          properties:
            number:
              type: "integer"
              minimum: 10
              maximum: 50
              divisibleBy: 10

      it "should not validate an empty value", ->
        result = @schema.process({divisibleBy: ""})
        expect(result.valid).toBe(true)

      it "should validate maximum", ->
        result = @schema.process({number: 100})
        expect(result.valid).toBe(false)
        expect(result.errors.on("number")).toEqual(["maximum"])

      it "should accept a value equal to maximum", ->
        expect(@schema.process({number: 50}).valid).toBe(true)

      it "should validate minimum", ->
        result = @schema.process({number: 0})
        expect(result.valid).toBe(false)
        expect(result.errors.on("number")).toEqual(["minimum"])

      it "should accept a value equal to minimum", ->
        expect(@schema.process({number: 10}).valid).toBe(true)

      it "should validate divisibleBy" , ->
        result = @schema.process({number: 35})
        expect(result.valid).toBe(false)
        expect(result.errors.on("number")).toEqual(["divisibleBy"])

      it "should validate both divisibleBy and minimum", ->
        result = @schema.process({number: 5})
        expect(result.valid).toBe(false)
        expect(result.errors.on("number")).toEqual(["minimum", "divisibleBy"])

      it "should handle excludeMinimum", ->
        @schema.properties.number.excludeMinimum = true
        expect(@schema.process({number: 20}).valid).toBe(true)
        expect(@schema.process({number: 10}).valid).toBe(false)
        expect(@schema.process({number: 10}).errors.on("number")).toEqual(["minimum"])

      it "should handle excludeMaximum", ->
        @schema.properties.number.excludeMaximum = true
        expect(@schema.process({number: 20}).valid).toBe(true)
        expect(@schema.process({number: 50}).valid).toBe(false)
        expect(@schema.process({number: 50}).errors.on("number")).toEqual(["maximum"])

  describe "arrays", ->
    beforeEach ->
      @schema = new JsonSchema
        type: "object"
        properties:
          array:
            type: "array"

    it "should handle array values", ->
      result = @schema.process({array: [1,"2",3]})
      expect(result.valid).toBe(true)
      expect(result.value.array).toEqual([1,"2",3])

    it "should validate minItems", ->
      @schema.properties.array.minItems = 3
      result = @schema.process({array: [1,2]})
      expect(result.valid).toBe(false)
      expect(result.errors.on("array")).toEqual(["minItems"])
      expect(@schema.process({array: [1,2,3]}).valid).toBe(true)

    it "should validate maxItems", ->
      @schema.properties.array.maxItems = 3
      result = @schema.process({array: [1,2,3,4]})
      expect(result.valid).toBe(false)
      expect(result.errors.on("array")).toEqual(["maxItems"])
      expect(@schema.process({array: [1,2,3]}).valid).toBe(true)

    describe "with numerical items", ->
      beforeEach ->
        @schema.properties.array.items =
          type: "integer"

      it "should cast array values", ->
        result = @schema.process({array: ["1", "2", "3"]})
        expect(result.valid).toBe(true)
        expect(result.value.array).toEqual([1,2,3])

      it "should validate array values", ->
        @schema.properties.array.items.minimum = 3
        result = @schema.process({array: [1, 2, 3]})
        expect(result.valid).toBe(false)
        expect(result.errors.on("array.0")).toEqual(["minimum"])
        expect(result.errors.on("array.1")).toEqual(["minimum"])
        expect(result.errors.on("array.2")).toBe(undefined)

  describe "objects", ->
    beforeEach ->
      @schema = new JsonSchema
        type: "object"
        properties:
          object:
            type: "object"
            properties:
              test:
                type: "string"

    it "should process an object", ->
      result = @schema.process({object: {test: "Hello"}})
      expect(result.value.object.test).toEqual("Hello")

    it "should validate properties on the object", ->
      @schema.properties.object.properties.test.minLength = 8
      result = @schema.process({object: {test: "Hello"}})
      expect(result.valid).toBe(false)
      expect(result.errors.on("object.test")).toEqual(["minLength"])

    it "should not make the object required when an property is required", ->
      @schema.properties.object.properties.test.required = true
      result = @schema.process({})
      console.log(result)
      expect(result.valid).toBe(true)

  describe "resolving refs", ->
    beforeEach ->
      schemas =
        person:
          type: "object"
          properties:
            name:
              type: "string"
              required: true
        party:
          type: "object"
          properties:
            host:
              type: "object"
              properties:
                "$ref": "person#.properties"
            guests:
              type: "array"
              items:
                "$ref": "person"

      JsonSchema.resolver = (uri, current) ->
        attr = schemas[uri]
        new JsonSchema(attr) if attr
      
      @schema = JsonSchema.resolver("party")
    
    it "should resolve an object reference", ->
      result = @schema.process({host: {name: "Mathias"}})
      expect(result.value.host.name).toEqual("Mathias")
      expect(result.valid).toBe(true)
      
      bad = @schema.process({host: {}})
      expect(bad.valid).toBe(false)
      expect(bad.errors.on("host.name")).toEqual(["required"])

    it "should resolve array references", ->
      result = @schema.process({guests: [{name: "Irene"}, {name: "Julio"}]})
      expect(result.value.guests[0].name).toEqual("Irene")
      expect(result.value.guests[1].name).toEqual("Julio")
      
      bad = @schema.process({guests: [{name: "Irene"}, {}]})
      expect(bad.valid).toBe(false)
      expect(bad.errors.on("guests.1.name")).toEqual(["required"])

describe "JsonErrors", ->
  it "should handle merging nested error objects", ->
    errors = new JsonErrors
    errors.add("required")

    arrayErrors = new JsonErrors
    arrayErrors.add("minItems")
    arrayErrors.add("0", "numeric")

    errors.add("array", arrayErrors)
    
    expect(errors.on("")).toEqual(["required"])
    expect(errors.on("array")).toEqual(["minItems"])
    expect(errors.on("array.0")).toEqual(["numeric"])