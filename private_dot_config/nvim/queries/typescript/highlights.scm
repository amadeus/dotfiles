;; inherits: typescript

(function_declaration
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(function_expression
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(arrow_function
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(method_definition
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(function_type
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(method_signature
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(call_signature
  parameters: (formal_parameters
    "(" @function.paren.open
    ")" @function.paren.close))

(function_declaration
  body: (statement_block
    "{" @function.bracket.open
    "}" @function.bracket.close))

(function_expression
  body: (statement_block
    "{" @function.bracket.open
    "}" @function.bracket.close))

(arrow_function
  body: (statement_block
    "{" @function.bracket.open
    "}" @function.bracket.close))

(function_declaration
  parameters: (formal_parameters
    (required_parameter
      name: (identifier) @function.parameter)))

(arrow_function
  parameters: (formal_parameters
    (required_parameter
      name: (identifier) @function.parameter)))

(method_definition
  parameters: (formal_parameters
    (required_parameter
      name: (identifier) @function.parameter)))

(function_expression
  parameters: (formal_parameters
    (required_parameter
      name: (identifier) @function.parameter)))

(function_declaration
  parameters: (formal_parameters
    (optional_parameter
      name: (identifier) @function.parameter.optional)))

(arrow_function
  parameters: (formal_parameters
    (optional_parameter
      name: (identifier) @function.parameter.optional)))

(method_definition
  parameters: (formal_parameters
    (optional_parameter
      name: (identifier) @function.parameter.optional)))

(required_parameter
  pattern: (array_pattern
    (identifier) @function.parameter.destructured))

(arrow_function
  parameter: (identifier) @function.parameter)

(arrow_function
  "=>" @arrow.function)

(required_parameter
  type: (type_annotation
    ":" @type.annotation.colon
    [
      (type_identifier) @type.annotation
      (predefined_type) @type.annotation.predefined
      (union_type) @type.annotation.union
      (intersection_type) @type.annotation.intersection
      (array_type) @type.annotation.array
      (tuple_type) @type.annotation.tuple
      (object_type) @type.annotation.object
      (generic_type) @type.annotation.generic
      (type_predicate) @type.annotation.predicate
      (literal_type) @type.annotation.literal
      (parenthesized_type) @type.annotation.parenthesized
    ]))

(optional_parameter
  type: (type_annotation
    ":" @type.annotation.colon
    [
      (type_identifier) @type.annotation
      (predefined_type) @type.annotation.predefined
      (union_type) @type.annotation.union
      (intersection_type) @type.annotation.intersection
      (array_type) @type.annotation.array
      (tuple_type) @type.annotation.tuple
      (object_type) @type.annotation.object
      (generic_type) @type.annotation.generic
      (type_predicate) @type.annotation.predicate
      (literal_type) @type.annotation.literal
      (parenthesized_type) @type.annotation.parenthesized
    ]))

(union_type
  (type_identifier) @type.annotation.union.member)

(union_type
  (predefined_type) @type.annotation.union.member.predefined)

(generic_type
  type_arguments: (type_arguments
    (type_identifier) @type.annotation.generic.argument))

((type_annotation) @type.annotation.high_priority
 (#has-ancestor? @type.annotation.high_priority formal_parameters)
 (#set! "priority" 110))

((true) @boolean.true
 (#set! "priority" 110))

((false) @boolean.false
 (#set! "priority" 110))

(class_declaration
  "class" @keyword.class)

(abstract_class_declaration
  "class" @keyword.class)

(abstract_class_declaration
  "abstract" @keyword.class.abstract)

((["class"]) @keyword.class.high_priority
 (#has-parent? @keyword.class.high_priority class_declaration)
 (#set! "priority" 110))

((["class"]) @keyword.class.high_priority
 (#has-parent? @keyword.class.high_priority abstract_class_declaration)
 (#set! "priority" 110))

(class_declaration
  name: (type_identifier) @class.name)

(abstract_class_declaration
  name: (type_identifier) @class.name)

((type_identifier) @class.name.high_priority
 (#has-parent? @class.name.high_priority class_declaration)
 (#set! "priority" 110))

((type_identifier) @class.name.high_priority
 (#has-parent? @class.name.high_priority abstract_class_declaration)
 (#set! "priority" 110))

(class_declaration
  body: (class_body
    "{" @class.brace.open
    "}" @class.brace.close))

(abstract_class_declaration
  body: (class_body
    "{" @class.brace.open
    "}" @class.brace.close))

((["{"]) @class.brace.open.high_priority
 (#has-ancestor? @class.brace.open.high_priority class_declaration)
 (#has-parent? @class.brace.open.high_priority class_body)
 (#set! "priority" 110))

((["}"]) @class.brace.close.high_priority
 (#has-ancestor? @class.brace.close.high_priority class_declaration)
 (#has-parent? @class.brace.close.high_priority class_body)
 (#set! "priority" 110))

((["{"]) @class.brace.open.high_priority
 (#has-ancestor? @class.brace.open.high_priority abstract_class_declaration)
 (#has-parent? @class.brace.open.high_priority class_body)
 (#set! "priority" 110))

((["}"]) @class.brace.close.high_priority
 (#has-ancestor? @class.brace.close.high_priority abstract_class_declaration)
 (#has-parent? @class.brace.close.high_priority class_body)
 (#set! "priority" 110))

(class_declaration
  body: (class_body
    "{" @class.bracket.open
    "}" @class.bracket.close))

(abstract_class_declaration
  body: (class_body
    "{" @class.bracket.open
    "}" @class.bracket.close))

((["{"]) @class.bracket.open.high_priority
 (#has-ancestor? @class.bracket.open.high_priority class_declaration)
 (#has-parent? @class.bracket.open.high_priority class_body)
 (#set! "priority" 110))

((["}"]) @class.bracket.close.high_priority
 (#has-ancestor? @class.bracket.close.high_priority class_declaration)
 (#has-parent? @class.bracket.close.high_priority class_body)
 (#set! "priority" 110))

((["{"]) @class.bracket.open.high_priority
 (#has-ancestor? @class.bracket.open.high_priority abstract_class_declaration)
 (#has-parent? @class.bracket.open.high_priority class_body)
 (#set! "priority" 110))

((["}"]) @class.bracket.close.high_priority
 (#has-ancestor? @class.bracket.close.high_priority abstract_class_declaration)
 (#has-parent? @class.bracket.close.high_priority class_body)
 (#set! "priority" 110))
