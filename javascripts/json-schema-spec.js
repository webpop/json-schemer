// Generated by CoffeeScript 1.3.3
(function() {

  describe("JsonSchema", function() {
    describe("with a simple example schema from the ietf draft", function() {
      beforeEach(function() {
        return this.schema = new JsonSchema({
          description: "A person",
          type: "object",
          properties: {
            name: {
              type: "string"
            },
            age: {
              type: "integer",
              maximum: 125
            }
          }
        });
      });
      it("should process an empty object", function() {
        var result;
        result = this.schema.process({});
        expect(Object.keys(result.value)).toEqual(['name', 'age']);
        expect(result.value.name).toBe(void 0);
        expect(result.value.age).toBe(void 0);
        return expect(result.valid).toBe(true);
      });
      it("should process a valid object", function() {
        var result;
        result = this.schema.process({
          name: "Mathias",
          age: 35
        });
        expect(Object.keys(result.value)).toEqual(["name", "age"]);
        expect(result.value.name).toEqual("Mathias");
        expect(result.value.age).toEqual(35);
        return expect(result.valid).toBe(true);
      });
      it("should cast strings to numbers where needed", function() {
        var result;
        result = this.schema.process({
          age: "35"
        });
        expect(result.value.age).toEqual(35);
        return expect(result.valid).toBe(true);
      });
      return it("should validate the maximum for a number", function() {
        var result;
        result = this.schema.process({
          age: 200
        });
        expect(result.value.age).toEqual(200);
        expect(result.valid).toBe(false);
        return expect(result.errors.age).toEqual(["maximum"]);
      });
    });
    describe("validations", function() {
      describe("optional and required fields", function() {
        beforeEach(function() {
          return this.schema = new JsonSchema({
            type: "object",
            properties: {
              optional: {
                type: "string"
              },
              required: {
                type: "string",
                required: true
              }
            }
          });
        });
        return it("should validate required fields", function() {
          var result;
          result = this.schema.process({});
          expect(result.valid).toBe(false);
          expect(result.errors.optional).toBe(void 0);
          return expect(result.errors.required).toEqual(["required"]);
        });
      });
      describe("string validations", function() {
        beforeEach(function() {
          return this.schema = new JsonSchema({
            type: "object",
            properties: {
              minlength: {
                type: "string",
                minLength: 1
              },
              maxlength: {
                type: "string",
                maxLength: 2
              },
              pattern: {
                type: "string",
                pattern: "^[a-z]+$"
              },
              "enum": {
                type: "string",
                "enum": ["one", "two", "three"]
              }
            }
          });
        });
        it("should validate the minLength", function() {
          var result;
          result = this.schema.process({
            minlength: ""
          });
          expect(result.valid).toBe(false);
          expect(result.errors.minlength).toEqual(["minLength"]);
          return expect(this.schema.process({
            minlength: "good"
          }).valid).toBe(true);
        });
        it("should validate the maxLength", function() {
          var result;
          result = this.schema.process({
            maxlength: "hello"
          });
          expect(result.valid).toBe(false);
          expect(result.errors.maxlength).toEqual(["maxLength"]);
          return expect(this.schema.process({
            maxlength: "It"
          }).valid).toBe(true);
        });
        it("should validate the pattern", function() {
          var result;
          result = this.schema.process({
            pattern: "Has Spaces"
          });
          expect(result.valid).toBe(false);
          expect(result.errors.pattern).toEqual(["pattern"]);
          return expect(this.schema.process({
            pattern: "nospaces"
          }).valid).toBe(true);
        });
        return it("should validate the enum", function() {
          var result;
          result = this.schema.process({
            "enum": "four"
          });
          expect(result.valid).toBe(false);
          expect(result.errors["enum"]).toEqual(["enum"]);
          return expect(this.schema.process({
            "enum": "two"
          }).valid).toBe(true);
        });
      });
      describe("date and time", function() {
        beforeEach(function() {
          return this.schema = new JsonSchema({
            type: "object",
            properties: {
              datetime: {
                type: "string",
                format: "date-time"
              },
              date: {
                type: "string",
                format: "date"
              }
            }
          });
        });
        it("should process a date", function() {
          var result;
          result = this.schema.process({
            date: "2012-07-09"
          });
          return expect(result.value.date.getFullYear()).toEqual(2012);
        });
        it("should process a date-time", function() {
          var result;
          result = this.schema.process({
            datetime: "2012-07-09T12:09:18Z"
          });
          return expect(result.value.datetime.getFullYear()).toEqual(2012);
        });
        return it("should validate a date", function() {
          var result;
          result = this.schema.process({
            date: "09/09/2012"
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.date).toEqual(["format"]);
        });
      });
      return describe("number validations", function() {
        beforeEach(function() {
          return this.schema = new JsonSchema({
            type: "object",
            properties: {
              number: {
                type: "integer",
                minimum: 10,
                maximum: 50,
                divisibleBy: 10
              }
            }
          });
        });
        it("should not validate an empty value", function() {
          var result;
          result = this.schema.process({
            divisibleBy: ""
          });
          return expect(result.valid).toBe(true);
        });
        it("should validate maximum", function() {
          var result;
          result = this.schema.process({
            number: 100
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.number).toEqual(["maximum"]);
        });
        it("should accept a value equal to maximum", function() {
          return expect(this.schema.process({
            number: 50
          }).valid).toBe(true);
        });
        it("should validate minimum", function() {
          var result;
          result = this.schema.process({
            number: 0
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.number).toEqual(["minimum"]);
        });
        it("should accept a value equal to minimum", function() {
          return expect(this.schema.process({
            number: 10
          }).valid).toBe(true);
        });
        it("should validate divisibleBy", function() {
          var result;
          result = this.schema.process({
            number: 35
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.number).toEqual(["divisibleBy"]);
        });
        it("should validate both divisibleBy and minimum", function() {
          var result;
          result = this.schema.process({
            number: 5
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.number).toEqual(["minimum", "divisibleBy"]);
        });
        it("should handle excludeMinimum", function() {
          this.schema.properties.number.excludeMinimum = true;
          expect(this.schema.process({
            number: 20
          }).valid).toBe(true);
          expect(this.schema.process({
            number: 10
          }).valid).toBe(false);
          return expect(this.schema.process({
            number: 10
          }).errors.number).toEqual(["minimum"]);
        });
        return it("should handle excludeMaximum", function() {
          this.schema.properties.number.excludeMaximum = true;
          expect(this.schema.process({
            number: 20
          }).valid).toBe(true);
          expect(this.schema.process({
            number: 50
          }).valid).toBe(false);
          return expect(this.schema.process({
            number: 50
          }).errors.number).toEqual(["maximum"]);
        });
      });
    });
    describe("arrays", function() {
      beforeEach(function() {
        return this.schema = new JsonSchema({
          type: "object",
          properties: {
            array: {
              type: "array"
            }
          }
        });
      });
      it("should handle array values", function() {
        var result;
        result = this.schema.process({
          array: [1, "2", 3]
        });
        expect(result.valid).toBe(true);
        return expect(result.value.array).toEqual([1, "2", 3]);
      });
      it("should validate minItems", function() {
        var result;
        this.schema.properties.array.minItems = 3;
        result = this.schema.process({
          array: [1, 2]
        });
        expect(result.valid).toBe(false);
        expect(result.errors.array).toEqual(["minItems"]);
        return expect(this.schema.process({
          array: [1, 2, 3]
        }).valid).toBe(true);
      });
      it("should validate maxItems", function() {
        var result;
        this.schema.properties.array.maxItems = 3;
        result = this.schema.process({
          array: [1, 2, 3, 4]
        });
        expect(result.valid).toBe(false);
        expect(result.errors.array).toEqual(["maxItems"]);
        return expect(this.schema.process({
          array: [1, 2, 3]
        }).valid).toBe(true);
      });
      return describe("with numerical items", function() {
        beforeEach(function() {
          return this.schema.properties.array.items = {
            type: "integer"
          };
        });
        it("should cast array values", function() {
          var result;
          result = this.schema.process({
            array: ["1", "2", "3"]
          });
          expect(result.valid).toBe(true);
          return expect(result.value.array).toEqual([1, 2, 3]);
        });
        return it("should validate array values", function() {
          var result;
          this.schema.properties.array.items.minimum = 3;
          result = this.schema.process({
            array: [1, 2, 3]
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.array).toEqual(["minimum"]);
        });
      });
    });
    return describe("objects", function() {
      beforeEach(function() {
        return this.schema = new JsonSchema({
          type: "object",
          properties: {
            object: {
              type: "object",
              properties: {
                test: {
                  type: "string"
                }
              }
            }
          }
        });
      });
      it("should process an object", function() {
        var result;
        result = this.schema.process({
          object: {
            test: "Hello"
          }
        });
        return expect(result.value.object.test).toEqual("Hello");
      });
      return it("should validate properties on the object", function() {
        var result;
        this.schema.properties.object.properties.test.minLength = 8;
        result = this.schema.process({
          object: {
            test: "Hello"
          }
        });
        expect(result.valid).toBe(false);
        return expect(result.errors.object.test).toEqual(["minLength"]);
      });
    });
  });

}).call(this);
