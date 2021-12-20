// ignore_for_file: avoid_function_literals_in_foreach_calls
import "package:dart_style/dart_style.dart"; // for formatting the generated code
import 'package:analyzer/dart/analysis/results.dart'; // for parsing the source
import 'package:analyzer/dart/analysis/utilities.dart'; // for building the AST
import 'package:analyzer/dart/ast/ast.dart' hide Expression; // for AST types
import 'package:analyzer/dart/ast/visitor.dart'; // for building AST visitors
import 'package:code_builder/code_builder.dart'; // for building code
import 'package:built_collection/built_collection.dart'; // for buildng parts as a list (constructors, parameters, etc.)

const sampleClass = """ 
class Person  { 
  final String name;
  final String? nickname;
  final int age;
  final double height;
  final List<String> hobbies;
}
"""; // expected output is shown under each builder section below

void main() {
  final ParseStringResult parsedSourceString = parseString(content: sampleClass);
  final CompilationUnit compilationUnit = parsedSourceString.unit;
  final classVisitor = ClassVisitor();
  // visit all the classes and class visitor willl accumulate them
  compilationUnit.visitChildren(classVisitor);
  // get all the classes
  final List<ClassDeclaration> classes = classVisitor.classes;

  final dataClasses = <String>[];
  // use it to format the generated code
  final formatter = DartFormatter(pageWidth: 120);
  for (var c in classes) {
    final dataClass = generateDataClass(c);
    final source = generateSourceFromSingleClass(dataClass);
    final formattedSource = formatter.format(source);
    dataClasses.add(formattedSource);
    print(formattedSource);
  }
  // final addCollectionImport = classVisitor.collectionExists;
  // TODO: replace the classes in the old source with the newly created dataClasses
}

/* -------------------------------------------------------------------------- */
/*                                    TODOS                                   */
/* -------------------------------------------------------------------------- */
// TODO: wrap all the functions in a class or classes as applicable
// TODO: handle toMap/fromMap for collections with Generic Custom Types e.g. List<Employees>
// TODO: handle deep equality for collections e.g. collectionEquals(other.list, list)
// TODO: include 'dart:convert' (for json.decode/encode) in generated code when serialization is generated
// TODO: include 'package:collection/collection.dart' import when using deep equality.
// TODO: replace classes in parsed source with generated data classes and put it into a new source.

/* -------------------------------------------------------------------------- */
/*                                    BASE                                    */
/* -------------------------------------------------------------------------- */

Class generateDataClass(ClassDeclaration clazz) {
  final extractedParameters = ExtractedParameter.extractParameters(clazz);
  final clazzBuilder = ClassBuilder();
  clazzBuilder
    ..name = clazz.name.name
    ..constructors = buildConstructors(clazz, extractedParameters)
    ..fields = buildClassFields(extractedParameters)
    ..methods = buildMethods(clazz, extractedParameters);

  return clazzBuilder.build();
}

/* -------------------------------------------------------------------------- */
/*                            CONSTRUCTORS BUILDERS                           */
/* -------------------------------------------------------------------------- */
ListBuilder<Constructor> buildConstructors(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  // TODO: build fromMap and fromJson factory consts
  final constructors = <Constructor>[
    buildUnnamedConstructor(extractedParameters),
    buildFromMapConstructor(clazz, extractedParameters),
    buildFromJsonConstructor(clazz),
  ];

  return ListBuilder(constructors);
}

/* -------------------------------------------------------------------------- */
/*                            CLASS FIELDS BUILDER                            */
/* -------------------------------------------------------------------------- */
// final String name;
// final String? nickname;
// final int age;
// final double height;
// final List<String> hobbies;
ListBuilder<Field> buildClassFields(List<ExtractedParameter> extractedParameters) {
  final fields = <Field>[];
  for (var param in extractedParameters) {
    final assignment = param.assignment != null ? Code(param.assignment!) : null;
    fields.add(Field((b) {
      b
        ..name = param.name
        ..modifier = FieldModifier.final$
        ..assignment = assignment
        ..type = param.typeRef;
    }));
  }

  return ListBuilder(fields);
}

/* -------------------------------------------------------------------------- */
/*                           CLASS METHODS BUILDERS                           */
/* -------------------------------------------------------------------------- */
ListBuilder<Method> buildMethods(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  final methods = <Method>[
    generateCopyWithMethod(clazz, extractedParameters),
    generateToJsonMethod(extractedParameters),
    generateToMapMethod(extractedParameters),
    generateToStringMethod(clazz, extractedParameters),
    generateEqualityOperator(clazz, extractedParameters),
    generateHashCodeGetter(extractedParameters),
  ];

  return ListBuilder(methods);
}

/* -------------------------------------------------------------------------- */
/*                           BUILDERS IMPLEMENTATION                          */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                             DEFAULT CONSTRUCTOR                            */
/* -------------------------------------------------------------------------- */
// const Person({
//   required this.name,
//   this.nickname,
//   required this.age,
//   required this.height,
//   required this.hobbies,
// });
Constructor buildUnnamedConstructor(List<ExtractedParameter> extractedParameters) {
  return Constructor((b) {
    b
      ..optionalParameters = buildConstructorNamedParameters(extractedParameters)
      ..constant = true;
  });
}

ListBuilder<Parameter> buildConstructorNamedParameters(List<ExtractedParameter> extractedParameters) {
  final namedParameters = <Parameter>[];
  extractedParameters.forEach((param) {
    if (param.isInitialized) return;
    namedParameters.add(
      Parameter(
        (b) {
          b
            ..name = param.name
            ..named = true
            ..toThis = true
            ..required = !param.isNullable;
        },
      ),
    );
  });

  if (namedParameters.isNotEmpty) {
    // a workaround to add a trailing comma by a trailing parameter with an empty name.
    // there's no method in the ConstructorBuilder to add a trailing comma nor is there one with in DartFormatter.
    namedParameters.add(Parameter((b) {
      b.name = '';
    }));
  }

  return ListBuilder(namedParameters);
}

/* -------------------------------------------------------------------------- */
/*                        fromJson Factory Constructor                        */
/* -------------------------------------------------------------------------- */
// TODO: include import 'dart:convert';
//  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));
Constructor buildFromJsonConstructor(ClassDeclaration clazz) {
  final name = clazz.name.name;
  return Constructor((b) {
    b
      ..name = 'fromJson'
      ..factory = true
      ..requiredParameters = ListBuilder<Parameter>([
        Parameter((b) {
          b
            ..name = 'source'
            ..type = refer('String');
        })
      ])
      ..lambda = true
      ..body = Code('$name.fromMap(json.decode(source))');
  });
}

/* -------------------------------------------------------------------------- */
/*                         fromMap Factory Constructor                        */
/* -------------------------------------------------------------------------- */
// factory Person.fromMap(Map<String, dynamic> map) {
//   return Person(
//     name: map['name'],
//     nickname: map['nickname'],
//     age: map['age'].toInt(),
//     height: map['height'].toDouble(),
//     hobbies: List<String>.from(map['hobbies']),
//   );
// }
Constructor buildFromMapConstructor(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  return Constructor((b) {
    b
      ..name = 'fromMap'
      ..factory = true
      ..requiredParameters = ListBuilder<Parameter>([
        Parameter((b) {
          b
            ..name = 'map'
            ..type = refer('Map<String, dynamic>');
        })
      ])
      ..body = generateFromMapConstructorBody(clazz, extractedParameters);
  });
}

Code generateFromMapConstructorBody(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  final body = extractedParameters
      .where((p) => !p.isInitialized)
      .map(buildFromMapField)
      .reduce((value, element) => value + ',' + element);
  return Code('return ${clazz.name.name}($body,);');
}

String buildFromMapField(ExtractedParameter param) {
  // TODO: we should capture the generic for Lists and Maps
  String symbol = removeGenericsFromType(param.symbol).replaceAll('?', '');
  final fieldName = param.name;
  String mapValue = "map['$fieldName']";
  final nullablel = param.isNullable;
  switch (symbol) {
    case 'num':
    case 'dynamic':
    case 'bool':
    case 'Object':
    case 'String':
      // do nothing e.g. map[fieldName] as is.
      break;
    case 'int':
      // - int --> map['fieldName']?.toInt()       OR     int.parse(map['fieldName'])
      mapValue = nullablel ? '$mapValue?.toInt()' : '$mapValue.toInt()';
      break;
    case 'double':
      // - double --> map['fieldName']?.double()   OR     double.parse(map['fieldName'])
      // note: dart, especially when used with web, would convert double to integer (1.0 -> 1) so account for it.
      mapValue = nullablel ? '$mapValue?.toDouble()' : '$mapValue.toDouble()';
      break;
    case 'List':
      // TODO: handle generics
      // e.g. List<int>.from(map['employeeIDs']) or List<Employee>.from(map['employee']?.map((x) => Employee.fromMap(x))),
      mapValue = nullablel ? '$mapValue == null ? null : List.from($mapValue)' : 'List.from($mapValue)';
      break;
    case 'Set':
      // TODO: handle generics
      // e.g. Set<int>.from(map['fieldName'])
      mapValue = nullablel ? '$mapValue == null ? null : Set.from($mapValue)' : 'Set.from($mapValue)';
      break;
    case 'Map':
      // TODO: handle generics
      // e.g. Map<int>.from(map['fieldName'])
      mapValue = nullablel ? '$mapValue == null ? null : Map.from($mapValue)' : 'Map.from($mapValue)';
      break;
    default:
      // CustomType --> CustomType.fromMap(map['fieldName'])
      mapValue = nullablel ? '$mapValue == null ? null : $fieldName.from($mapValue)' : '$fieldName.from($mapValue)';
      break;
  }
  return '$fieldName: $mapValue';
}

/* -------------------------------------------------------------------------- */
/*                                toMap METHOD                                */
/* -------------------------------------------------------------------------- */

// Map<String, dynamic> toMap() {
//   return {
//     'name': name,
//     'nickname': nickname,
//     'age': age,
//     'height': height,
//     'hobbies': hobbies,
//   };
// }
Method generateToMapMethod(List<ExtractedParameter> extractedParameters) {
  return Method((b) {
    b
      ..name = 'toMap'
      ..returns = refer('Map<String, dynamic>')
      ..body = generateToMapMethodBody(extractedParameters);
  });
}

Code generateToMapMethodBody(List<ExtractedParameter> extractedParameters) {
  final body = extractedParameters
      .where((p) => !p.isInitialized)
      .map(buildToMapField)
      .reduce((value, element) => value + ',' + element);
  return Code('return {$body,};');
}

String buildToMapField(ExtractedParameter param) {
  // TODO: we should capture the generic for Lists and Maps
  String symbol = removeGenericsFromType(param.symbol).replaceAll('?', '');
  final fieldName = param.name;
  String mapValue = fieldName;
  final nullablel = param.isNullable;
  switch (symbol) {
    case 'num':
    case 'dynamic':
    case 'Object':
    case 'String':
    case 'int':
    case 'double':
    case 'bool':
      // return as is 'map[fieldName]'
      break;
    case 'List':
      // todo: handle generics (if the generic is a basic type accepted by json, leave as is)
      //  e.g. employees.map((x) => x.toMap()).toList(),
      // mapValue = nullablel ? '$mapValue == null ? null : List.from($mapValue)' : 'List.from($mapValue)';
      break;
    case 'Set':
      // todo: handle generics (if the generic is a basic type accepted by json, leave as is)
      // mapValue = nullablel ? '$mapValue == null ? null : Set.from($mapValue)' : 'Set.from($mapValue)';
      break;
    case 'Map':
      // todo: handle generics (if the generic is a basic type accepted by json, leave as is)
      // mapValue = nullablel ? '$mapValue == null ? null : Map.from($mapValue)' : 'Map.from($mapValue)';
      break;
    default:
      mapValue = nullablel ? '$mapValue?.toMap()' : '$mapValue.toMap()';
      break;
  }

  return "'$fieldName': $mapValue";
}

/* -------------------------------------------------------------------------- */
/*                               toJson() METHOD                              */
/* -------------------------------------------------------------------------- */
//  String toJson() => json.encode(toMap());
Method generateToJsonMethod(List<ExtractedParameter> extractedParameters) {
  return Method((b) {
    b
      ..name = 'toJson'
      ..returns = refer('String')
      ..lambda = true
      ..body = Code('json.encode(toMap())');
  });
}

/* -------------------------------------------------------------------------- */
/*                               copyWith METHOD                              */
/* -------------------------------------------------------------------------- */
// Person copyWith({
//   String? name,
//   String? nickname,
//   int? age,
//   double? height,
//   List<String>? hobbies,
// }) {
//   return Person(
//     name: name ?? this.name,
//     nickname: nickname ?? this.nickname,
//     age: age ?? this.age,
//     height: height ?? this.height,
//     hobbies: hobbies ?? this.hobbies,
//   );
// }
Method generateCopyWithMethod(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  final copyWithMethod = Method((b) {
    b
      ..returns = refer(clazz.name.name)
      ..name = 'copyWith'
      ..body = generateCopyWithBody(clazz, extractedParameters)
      ..optionalParameters = generateCopyWithMethodParameters(extractedParameters);
  });

  return copyWithMethod;
}

ListBuilder<Parameter> generateCopyWithMethodParameters(List<ExtractedParameter> extractedParameters) {
  final parameters = <Parameter>[];

  parameters.addAll(
    extractedParameters.where((p) => !p.isInitialized).map(
          (p) => Parameter(
            (b) {
              b
                ..name = p.name
                ..named = true
                ..type = p.typeRefAsNullable;
            },
          ),
        ),
  );

  if (parameters.isNotEmpty) {
    // to force adding a trailing comma
    parameters.add(Parameter((b) => b.name = ''));
  }

  return ListBuilder(parameters);
}

Code generateCopyWithBody(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  final body = extractedParameters
      .where((p) => !p.isInitialized)
      .map((p) => '${p.name}: ${p.name} ?? this.${p.name}')
      .reduce((value, element) => value + ',' + element);
  return Code('return ${clazz.name.name}($body,);');
}

/* -------------------------------------------------------------------------- */
/*                           EQUALITY AND HASH CODE                           */
/* -------------------------------------------------------------------------- */
// TODO: handle collection equality
// @override
// bool operator ==(Object other) {
//   if (identical(this, other)) return true;
//   return other is Person &&
//       other.name == name &&
//       other.nickname == nickname &&
//       other.age == age &&
//       other.height == height &&
//       other.hobbies == hobbies;
// }
Method generateEqualityOperator(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  return Method((b) {
    b
      ..name = '=='
      ..returns = refer('bool operator')
      ..requiredParameters = ListBuilder([
        Parameter((b) {
          b
            ..name = 'other'
            ..type = refer('Object');
        })
      ])
      ..annotations = overrideAnnotation()
      ..body = generateEqualityOperatorBody(clazz, extractedParameters);
  });
}

Code generateEqualityOperatorBody(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  final className = clazz.name.name;
  final fields =
      extractedParameters.map((p) => 'other.${p.name} == ${p.name}').reduce((prev, next) => prev + '&&' + next);
  return Code('''
  if (identical(this, other)) return true;
  // TODO: handle list equality here 
  return other is $className && $fields;
  ''');
}

// @override
// int get hashCode {
//   return name.hashCode ^ nickname.hashCode ^ age.hashCode ^ height.hashCode ^ hobbies.hashCode;
// }
Method generateHashCodeGetter(List<ExtractedParameter> extractedParameters) {
  final fields = extractedParameters.map((p) => '${p.name}.hashCode').reduce((prev, next) => prev + '^' + next);
  return Method((b) {
    b
      ..name = 'hashCode'
      ..type = MethodType.getter
      ..returns = refer('int')
      ..annotations = overrideAnnotation()
      ..body = Code('return $fields;');
  });
}

/* -------------------------------------------------------------------------- */
/*                                  toString                                  */
/* -------------------------------------------------------------------------- */

// @override
// String toString() {
//   return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies)';
// }
Method generateToStringMethod(ClassDeclaration clazz, List<ExtractedParameter> extractedParameters) {
  final className = clazz.name.name;
  final fields = extractedParameters.map((p) => p.name + ': ' '\$${p.name}').reduce((prev, next) => prev + ', ' + next);
  return Method((b) {
    b
      ..name = 'toString'
      ..returns = refer('String')
      ..annotations = overrideAnnotation()
      ..body = Code("return '$className($fields)';");
  });
}

/* -------------------------------------------------------------------------- */
/*                               HELPER CLASSES                               */
/* -------------------------------------------------------------------------- */

class ClassVisitor extends SimpleAstVisitor {
  final bool includeAbstract;
  ClassVisitor({
    this.includeAbstract = false,
  });

  final _collectionFinder = FindCollectionVisitor();

  bool get collectionExists => _collectionFinder.foundCollection;

  final classes = <ClassDeclaration>[];
  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (includeAbstract || !node.isAbstract) {
      if (!_collectionFinder.foundCollection) {
        node.accept(_collectionFinder);
      }
      classes.add(node);
    }
  }
}

class FindCollectionVisitor extends RecursiveAstVisitor {
  final collectionReg = RegExp(r'List|Map|Set');
  bool foundCollection = false;
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    // for some reason node.fields.type.type is always null
    // (node.fields.type.type  is a DartType and has some checks like isDartCoreList etc);
    final typeName = node.fields.type?.toSource() ?? '';
    if (typeName.startsWith(collectionReg)) {
      foundCollection = true;
    }
    if (foundCollection) {
      return;
    } else {
      return super.visitFieldDeclaration(node);
    }
  }
}

class ExtractedParameter {
  final String name;
  final bool isNullable;
  final bool isInitialized;
  final String symbol;
  final Reference typeRef;
  final String? assignment;

  ExtractedParameter({
    required this.name,
    required this.isNullable,
    required this.isInitialized,
    required this.symbol,
    this.assignment,
  }) : typeRef = refer(symbol);

  Reference? get typeRefAsNullable => isNullable ? typeRef : refer(symbol + '?');

  static List<ExtractedParameter> extractParameters(ClassDeclaration clazz) {
    final parameters = <ExtractedParameter>[];
    for (var member in clazz.members.whereType<FieldDeclaration>()) {
      // this applies to all variables
      final type = member.fields.type?.toSource() ?? 'dynamic';
      final isNullable = member.fields.type?.question != null || type == 'dynamic';
      // note: member.fields.variables is a List since once can define multiple variables within the same declaration
      //       such as: `final int x, y, z;` or `final int x = 0, y = 1, z = 3;`
      for (var variable in member.fields.variables) {
        final name = variable.name.name;
        final isInitialized = variable.initializer != null;
        final assignment = isInitialized ? variable.initializer!.toSource() : null;
        parameters.add(
          ExtractedParameter(
            name: name,
            isNullable: isNullable,
            isInitialized: isInitialized,
            symbol: type,
            assignment: assignment,
          ),
        );
      }
    }
    return parameters;
  }
}

/* -------------------------------------------------------------------------- */
/*                                   GENERAL                                  */
/* -------------------------------------------------------------------------- */

String generateSourceFromSingleClass(Class clazz) {
  final str = clazz.accept(DartEmitter());
  return str.toString();
}

final genericRegExp = RegExp(r'<.*>');

String removeGenericsFromType(String string) {
  return string.replaceAll(genericRegExp, '');
}

ListBuilder<Expression> overrideAnnotation() {
  return ListBuilder(const [CodeExpression(Code('override'))]);
}
