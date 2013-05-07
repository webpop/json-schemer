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
            },
            alive: {
              type: "boolean"
            }
          }
        });
      });
      it("should process an empty object", function() {
        var result;
        result = this.schema.process({});
        expect(Object.keys(result.doc)).toEqual(['name', 'age', 'alive']);
        expect(result.doc.name).toBe(void 0);
        expect(result.doc.age).toBe(void 0);
        return expect(result.valid).toBe(true);
      });
      it("should process a valid object", function() {
        var result;
        result = this.schema.process({
          name: "Mathias",
          age: 35
        });
        expect(Object.keys(result.doc)).toEqual(["name", "age", "alive"]);
        expect(result.doc.name).toEqual("Mathias");
        expect(result.doc.age).toEqual(35);
        return expect(result.valid).toBe(true);
      });
      it("should cast strings to numbers where needed", function() {
        var result;
        result = this.schema.process({
          age: "35"
        });
        expect(result.doc.age).toEqual(35);
        return expect(result.valid).toBe(true);
      });
      it("should validate the maximum for a number", function() {
        var result;
        result = this.schema.process({
          age: 200
        });
        expect(result.doc.age).toEqual(200);
        expect(result.valid).toBe(false);
        return expect(result.errors.all()).toEqual([["age", ["maximum"]]]);
      });
      it("should use a default value", function() {
        var result;
        this.schema.properties.name["default"] = "Default";
        result = this.schema.process({});
        return expect(result.doc.name).toEqual("Default");
      });
      it("should not set an undefined boolean value", function() {
        var result;
        result = this.schema.process({
          age: 200
        });
        return expect(result.doc.alive).toEqual(void 0);
      });
      return it("should set a boolean", function() {
        var result;
        result = this.schema.process({
          alive: true
        });
        expect(result.doc.alive).toEqual(true);
        result = this.schema.process({
          alive: "true"
        });
        expect(result.doc.alive).toEqual(true);
        result = this.schema.process({
          alive: "false"
        });
        return expect(result.doc.alive).toEqual(false);
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
          expect(result.errors.on("optional")).toBe(void 0);
          return expect(result.errors.on("required")).toEqual(["required"]);
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
          expect(result.errors.on("minlength")).toEqual(["minLength"]);
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
          expect(result.errors.on("maxlength")).toEqual(["maxLength"]);
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
          expect(result.errors.on("pattern")).toEqual(["pattern"]);
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
          expect(result.errors.on("enum")).toEqual(["enum"]);
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
          return expect(result.doc.date.getFullYear()).toEqual(2012);
        });
        it("should process a date-time", function() {
          var result;
          result = this.schema.process({
            datetime: "2012-07-09T12:09:18Z"
          });
          return expect(result.doc.datetime.getFullYear()).toEqual(2012);
        });
        return it("should validate a date", function() {
          var result;
          result = this.schema.process({
            date: "09/09/2012"
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.on("date")).toEqual(["format"]);
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
          return expect(result.errors.on("number")).toEqual(["maximum"]);
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
          return expect(result.errors.on("number")).toEqual(["minimum"]);
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
          return expect(result.errors.on("number")).toEqual(["divisibleBy"]);
        });
        it("should validate both divisibleBy and minimum", function() {
          var result;
          result = this.schema.process({
            number: 5
          });
          expect(result.valid).toBe(false);
          return expect(result.errors.on("number")).toEqual(["minimum", "divisibleBy"]);
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
          }).errors.on("number")).toEqual(["minimum"]);
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
          }).errors.on("number")).toEqual(["maximum"]);
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
        return expect(result.doc.array).toEqual([1, "2", 3]);
      });
      it("should validate minItems", function() {
        var result;
        this.schema.properties.array.minItems = 3;
        result = this.schema.process({
          array: [1, 2]
        });
        expect(result.valid).toBe(false);
        expect(result.errors.on("array")).toEqual(["minItems"]);
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
        expect(result.errors.on("array")).toEqual(["maxItems"]);
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
          return expect(result.doc.array).toEqual([1, 2, 3]);
        });
        return it("should validate array values", function() {
          var result;
          this.schema.properties.array.items.minimum = 3;
          result = this.schema.process({
            array: [1, 2, 3]
          });
          expect(result.valid).toBe(false);
          expect(result.errors.on("array.0")).toEqual(["minimum"]);
          expect(result.errors.on("array.1")).toEqual(["minimum"]);
          return expect(result.errors.on("array.2")).toBe(void 0);
        });
      });
    });
    describe("objects", function() {
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
        return expect(result.doc.object.test).toEqual("Hello");
      });
      it("should validate properties on the object", function() {
        var result;
        this.schema.properties.object.properties.test.minLength = 8;
        result = this.schema.process({
          object: {
            test: "Hello"
          }
        });
        expect(result.valid).toBe(false);
        return expect(result.errors.on("object.test")).toEqual(["minLength"]);
      });
      return it("should not make the object required when an property is required", function() {
        var result;
        this.schema.properties.object.properties.test.required = true;
        result = this.schema.process({});
        return expect(result.valid).toBe(true);
      });
    });
    return describe("resolving refs", function() {
      beforeEach(function() {
        var schemas;
        schemas = {
          person: {
            type: "object",
            properties: {
              name: {
                type: "string",
                required: true
              }
            }
          },
          party: {
            type: "object",
            properties: {
              host: {
                type: "object",
                properties: {
                  "$ref": "person#.properties"
                }
              },
              guests: {
                type: "array",
                items: {
                  "$ref": "person"
                }
              }
            }
          }
        };
        JsonSchema.resolver = function(uri, current) {
          var attr;
          attr = schemas[uri];
          if (attr) {
            return new JsonSchema(attr);
          }
        };
        return this.schema = JsonSchema.resolver("party");
      });
      it("should resolve an object reference", function() {
        var bad, result;
        result = this.schema.process({
          host: {
            name: "Mathias"
          }
        });
        expect(result.doc.host.name).toEqual("Mathias");
        expect(result.valid).toBe(true);
        bad = this.schema.process({
          host: {}
        });
        expect(bad.valid).toBe(false);
        return expect(bad.errors.on("host.name")).toEqual(["required"]);
      });
      return it("should resolve array references", function() {
        var bad, result;
        result = this.schema.process({
          guests: [
            {
              name: "Irene"
            }, {
              name: "Julio"
            }
          ]
        });
        expect(result.doc.guests[0].name).toEqual("Irene");
        expect(result.doc.guests[1].name).toEqual("Julio");
        bad = this.schema.process({
          guests: [
            {
              name: "Irene"
            }, {}
          ]
        });
        expect(bad.valid).toBe(false);
        return expect(bad.errors.on("guests.1.name")).toEqual(["required"]);
      });
    });
  });

  describe("JsonErrors", function() {
    return it("should handle merging nested error objects", function() {
      var arrayErrors, errors;
      errors = new JsonErrors;
      errors.add("required");
      arrayErrors = new JsonErrors;
      arrayErrors.add("minItems");
      arrayErrors.add("0", "numeric");
      errors.add("array", arrayErrors);
      expect(errors.on("")).toEqual(["required"]);
      expect(errors.on("array")).toEqual(["minItems"]);
      return expect(errors.on("array.0")).toEqual(["numeric"]);
    });
  });

}).call(this);
