import "package:dart_style/dart_style.dart";
import 'package:code_builder/code_builder.dart';
import 'package:built_collection/built_collection.dart';

// the example will build the following code:
/* 
      class Size {
        /// A representation of a size
        const Size(this.x, this.y);

        final double x;

        final double y;
      }
*/

void main() {
  final formatter = DartFormatter(pageWidth: 120);
  final clazzName = 'Size';
  // final parameters = 'String name';
  final clazz = buildClass(clazzName);
  final source = generateSourceFromSingleClass(clazz);
  print(formatter.format(source));
}

Class buildClass(String name) {
  final clazzBuilder = ClassBuilder();
  clazzBuilder
    ..name = name
    ..constructors = buildConstructor()
    ..fields = buildFields();

  return clazzBuilder.build();
}

ListBuilder<Constructor> buildConstructor() {
  final constructor = Constructor((b) {
    b
      ..optionalParameters = ListBuilder<Parameter>([
        Parameter((b) {
          b
            ..name = 'x'
            ..named = true
            ..required = true
            ..toThis = true;
        }),
        Parameter((b) {
          b
            ..name = 'y'
            ..named = true
            ..required = false
            ..defaultTo = Code('0.0')
            ..toThis = true;
        })
      ])
      ..constant = true
      ..docs = ListBuilder<String>(['/// A representation of a size']);
  });
  return ListBuilder<Constructor>([constructor]);
}

ListBuilder<Field> buildFields() {
  final fields = <Field>[];

  fields.add(Field((b) {
    b
      ..name = 'x'
      ..modifier = FieldModifier.final$
      ..type = refer('double');
  }));

  fields.add(Field((b) {
    b
      ..name = 'y'
      ..modifier = FieldModifier.final$
      ..type = refer('double');
  }));

  return ListBuilder(fields);
}

String generateSourceFromSingleClass(Class clazz) {
  final str = clazz.accept(DartEmitter());
  return str.toString();
}
