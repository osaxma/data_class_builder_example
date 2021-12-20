// ignore_for_file: avoid_function_literals_in_foreach_calls
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final sample = """ 
class Employee  { 
  final int id;
  final String firstName;
  final String lastName;
  final String managerID;
  final String departmentName = 'other';
  final String? nickname;
}

class Manager { 
  final int id;
  final String firstName;
  final String lastName;
  final List<int> employeeIDs;
  final String departmentName = 'other';
  final String? nickname;
}
""";

void main() {
  final ParseStringResult parsedString = parseString(
    content: sample,
  );

  final compUnit = parsedString.unit;
  final classes = getAllClasses(compUnit);

  printClassesExtentAndTheirFieldDeclaration(classes);
  /* prints: 
name: Employee starts at offset 0 with a length of 180
  -keyword: final -- type: int        -- isNullable: false -- name:id
  -keyword: final -- type: String     -- isNullable: false -- name:firstName
  -keyword: final -- type: String     -- isNullable: false -- name:lastName
  -keyword: final -- type: String     -- isNullable: false -- name:managerID
  -keyword: final -- type: String     -- isNullable: false -- name:departmentName
  -keyword: final -- type: String?    -- isNullable: true -- name:nickname
name: Manager starts at offset 182 with a length of 183
  -keyword: final -- type: int        -- isNullable: false -- name:id
  -keyword: final -- type: String     -- isNullable: false -- name:firstName
  -keyword: final -- type: String     -- isNullable: false -- name:lastName
  -keyword: final -- type: List<int>  -- isNullable: false -- name:employeeIDs
  -keyword: final -- type: String     -- isNullable: false -- name:departmentName
  -keyword: final -- type: String?    -- isNullable: true -- name:nickname
 */
}

/* -------------------------------------------------------------------------- */
/*                                  FUNCTIONS                                 */
/* -------------------------------------------------------------------------- */
List<ClassDeclaration> getAllClasses(CompilationUnit unit) {
  final classVisitor = ClassVisitor();
  unit.visitChildren(classVisitor);
  return classVisitor.classes;
}

void printClassesExtentAndTheirFieldDeclaration(List<ClassDeclaration> classes) {
  for (final clazz in classes) {
    print('name: ${clazz.name.name} starts at offset ${clazz.offset} with a length of ${clazz.length}');
    clazz.members.forEach((member) {
      if (member is FieldDeclaration) {
        final type = member.fields.type?.toSource().padRight(9); // member.fields.type
        final keyword = member.fields.keyword;
        final name = member.fields.variables.first.name.name.padLeft(1);
        final initializer = member.fields.variables.first.initializer;
        final defaultValue = initializer == null ? '' : ' =' + initializer.toSource();
        final isNullable = member.fields.type?.question != null;
            // note: member.fields.variables is a List since once can define multiple variables within the same declaration
            //       such as: `final int x, y, z;` or `final int x = 0, y = 1, z = 3;`
            print('-keyword: $keyword -- type: $type  -- isNullable: $isNullable -- name:$name');
      }
    });
  }
}

void printAllClassesNames(CompilationUnit unit) {
  unit.visitChildren(ClassVisitor());
}

void printAllErrors(ParseStringResult result) {
  print(result.errors);
}

/* -------------------------------------------------------------------------- */
/*                                  VISITORS                                  */
/* -------------------------------------------------------------------------- */

class ClassVisitor extends SimpleAstVisitor {
  ClassVisitor({
    this.includeAbstract = false,
  });

  final bool includeAbstract;
  final classes = <ClassDeclaration>[];
  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (includeAbstract || !node.isAbstract) {
      classes.add(node);
    }
  }
}

class SampleVisitor extends RecursiveAstVisitor {
  @override
  visitLibraryIdentifier(LibraryIdentifier node) {
    // TODO: implement visitLibraryIdentifier
    return super.visitLibraryIdentifier(node);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    // TODO: implement visitLibraryDirective
    return super.visitLibraryDirective(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    print(node.name.name);
    return super.visitClassDeclaration(node);
  }

  @override
  visitComment(Comment node) {
    // print();
    node.tokens.forEach((element) {
      print(element.value());
      print('token runtimeType ${element.runtimeType}');
    });
    return super.visitComment(node);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    node.fields.variables.forEach((element) {
      print(element.name.name);
    });
    // print();
    return super.visitFieldDeclaration(node);
  }
}
