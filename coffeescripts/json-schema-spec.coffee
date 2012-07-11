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
      runs -> @schema.process {}, (err, result) =>
        console.log("Got %o", result)
        expect(Object.keys(result.doc)).toEqual(['name', 'age'])
        expect(result.doc.name).toBe(undefined)
        expect(result.doc.age).toBe(undefined)
        expect(result.valid).toBe(true)

    it "should process a valid object", ->
      runs -> @schema.process {name: "Mathias", age: 35}, (err, result) =>
        expect(Object.keys(result.doc)).toEqual(["name", "age"])
        expect(result.doc.name).toEqual("Mathias")
        expect(result.doc.age).toEqual(35)
        expect(result.valid).toBe(true)

    it "should cast strings to numbers where needed", ->
      runs -> @schema.process {age: "35"}, (err, result) =>
        expect(result.doc.age).toEqual(35)
        expect(result.valid).toBe(true)

    it "should validate the maximum for a number", ->
      runs -> @schema.process {age: 200}, (err, result) =>
        expect(result.doc.age).toEqual(200)
        expect(result.valid).toBe(false)
        expect(result.errors.all()).toEqual([["age", ["maximum"]]])

    it "should use a default value", ->
      @schema.properties.name.default = "Default"
      runs -> @schema.process {}, (err, result) =>
        expect(result.doc.name).toEqual("Default")

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
        runs -> @schema.process {}, (err, result) =>
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
        runs -> @schema.process {minlength: ""}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("minlength")).toEqual(["minLength"])
        
        runs -> @schema.process {minlength: "good"}, (err, result) =>
          expect(result.valid).toBe(true)

      it "should validate the maxLength", ->
        runs -> @schema.process {maxlength: "hello"}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("maxlength")).toEqual(["maxLength"])
        runs -> @schema.process {maxlength: "It"}, (err, result) =>
          expect(result.valid).toBe(true)

      it "should validate the pattern", ->
        runs -> @schema.process {pattern: "Has Spaces"}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("pattern")).toEqual(["pattern"])
        runs -> @schema.process {pattern: "nospaces"}, (err, result) =>
          expect(result.valid).toBe(true)

      it "should validate the enum", ->
        runs -> @schema.process {enum: "four"}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("enum")).toEqual(["enum"])
        runs -> @schema.process {enum: "two"}, (err, result) =>
          expect(result.valid).toBe(true)

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
        runs -> @schema.process {date: "2012-07-09"}, (err, result) =>
          expect(result.doc.date.getFullYear()).toEqual(2012)

      it "should process a date-time", ->
        runs -> @schema.process {datetime: "2012-07-09T12:09:18Z"}, (err, result) =>
          expect(result.doc.datetime.getFullYear()).toEqual(2012)

      it "should validate a date", ->
        runs -> @schema.process {date: "09/09/2012"}, (err, result) =>
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
        runs -> @schema.process {divisibleBy: ""}, (err, result) =>
          expect(result.valid).toBe(true)

      it "should validate maximum", ->
        runs -> @schema.process {number: 100}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("number")).toEqual(["maximum"])

      it "should accept a value equal to maximum", ->
        runs -> @schema.process {number: 50}, (err, result) =>
          expect(result.valid).toBe(true)

      it "should validate minimum", ->
        runs -> @schema.process {number: 0}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("number")).toEqual(["minimum"])

      it "should accept a value equal to minimum", ->
        runs -> @schema.process {number: 10}, (err, result) =>
          expect(result.valid).toBe(true)

      it "should validate divisibleBy" , ->
        runs -> @schema.process {number: 35}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("number")).toEqual(["divisibleBy"])

      it "should validate both divisibleBy and minimum", ->
        runs -> @schema.process {number: 5}, (err, result) =>
          expect(result.valid).toBe(false)
          expect(result.errors.on("number")).toEqual(["minimum", "divisibleBy"])

      it "should handle excludeMinimum", ->
        @schema.properties.number.excludeMinimum = true
        runs -> @schema.process {number: 20}, (err, result) -> expect(result.valid).toBe(true)
        runs -> @schema.process {number: 10}, (err, result) -> expect(result.valid).toBe(false)
        runs -> @schema.process {number: 10}, (err, result) ->
          expect(result.errors.on("number")).toEqual(["minimum"])

      it "should handle excludeMaximum", ->
        @schema.properties.number.excludeMaximum = true
        runs -> @schema.process {number: 20}, (err, result) -> expect(result.valid).toBe(true)
        runs -> @schema.process {number: 50}, (err, result) -> expect(result.valid).toBe(false)
        runs -> @schema.process {number: 50}, (err, result) ->
          expect(result.errors.on("number")).toEqual(["maximum"])

  describe "arrays", ->
    beforeEach ->
      @schema = new JsonSchema
        type: "object"
        properties:
          array:
            type: "array"

    it "should handle array values", ->
      runs -> @schema.process {array: [1,"2",3]}, (err, result) =>
        expect(result.valid).toBe(true)
        expect(result.doc.array).toEqual([1,"2",3])

    it "should validate minItems", ->
      @schema.properties.array.minItems = 3
      runs -> @schema.process {array: [1,2]}, (err, result) =>
        expect(result.valid).toBe(false)
        expect(result.errors.on("array")).toEqual(["minItems"])
      runs -> @schema.process {array: [1,2,3]}, (err, result) =>
        expect(result.valid).toBe(true)

    it "should validate maxItems", ->
      @schema.properties.array.maxItems = 3
      runs -> @schema.process {array: [1,2,3,4]}, (err, result) =>
        expect(result.valid).toBe(false)
        expect(result.errors.on("array")).toEqual(["maxItems"])
      runs -> @schema.process {array: [1,2,3]}, (err, result) =>
        expect(result.valid).toBe(true)

    describe "with numerical items", ->
      beforeEach ->
        @schema.properties.array.items =
          type: "integer"

      it "should cast array values", ->
        console.log("Should cast array values")
        runs -> @schema.process {array: ["1", "2", "3"]}, (err, result) =>
          expect(result.valid).toBe(true)
          expect(result.doc.array).toEqual([1,2,3])

      it "should validate array values", ->
        @schema.properties.array.items.minimum = 3
        runs -> @schema.process {array: [1, 2, 3]}, (err, result) =>
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
      runs -> @schema.process {object: {test: "Hello"}}, (err, result) =>
        expect(result.doc.object.test).toEqual("Hello")

    it "should validate properties on the object", ->
      @schema.properties.object.properties.test.minLength = 8
      runs -> @schema.process {object: {test: "Hello"}}, (err, result) =>
        expect(result.valid).toBe(false)
        expect(result.errors.on("object.test")).toEqual(["minLength"])

    it "should not make the object required when an property is required", ->
      @schema.properties.object.properties.test.required = true
      runs -> @schema.process {}, (err, result) =>
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

      JsonSchema.resolver = (uri, current, cb) ->
        attr = schemas[uri]
        if attr then cb(null, new JsonSchema(attr)) else cb()
      
      @schema = new JsonSchema(schemas["party"])
    
    it "should resolve an object reference", ->
      runs -> @schema.process {host: {name: "Mathias"}}, (err, result) =>
        expect(result.doc.host.name).toEqual("Mathias")
        expect(result.valid).toBe(true)
      
      runs -> @schema.process {host: {}}, (err, result) =>
        expect(result.valid).toBe(false)
        expect(result.errors.on("host.name")).toEqual(["required"])

    it "should resolve array references", ->
      runs -> @schema.process {guests: [{name: "Irene"}, {name: "Julio"}]}, (err, result) =>
        expect(result.doc.guests[0].name).toEqual("Irene")
        expect(result.doc.guests[1].name).toEqual("Julio")
      
      runs -> @schema.process {guests: [{name: "Irene"}, {}]}, (err, result) =>
        expect(result.valid).toBe(false)
        expect(result.errors.on("guests.1.name")).toEqual(["required"])

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