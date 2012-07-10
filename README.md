#### Json Schemer

is a json-schema validator with a twist: instead of just validating json documents,
it will also cast the values of a document to fit a schema.

This is very handy if you need to process form submissions where all data comes
in form of strings.

#### Usage

To process a schema:

    schema = new JsonSchema
      type: "object"
        properties:
          name:
            type: "string"
            required: true
          age:
            type: "integer"
    
    result = schema.process({name: "Mathias", age: "35"})
    result.valid == true
    result.doc   == {name: "Mathias", age: 35}
    result.errors.isEmpty() == true

    result = schema.process({title: "Bad Doc"})
    result.valid == false
    result.doc   == {}
    result.errors.on("name") == ["required"]

### License

JSON Schemer (C) 2012 Mathias Biilmann Christensen

MIT License:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.