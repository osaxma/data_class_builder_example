### What is this?

Some examples for how to build dart code from another dart code using `package:analyzer` and `package:code_builder` only (i.e. no `build_runner` or `build.yaml` files). 

In the `example` folder, there are three different stand-alone examples. Each one of them can be simply ran as follow:

```sh
[~/path/to/repo] dart run example/<file_name>.dart
```

- [`ast_example`](example/ast_example.dart)
    - Shows how an Abstract Syntax Tree (AST) can be generated from a source code using `package:analyzer`.
    - How to visit elements in the tree. 

<br>

- [`code_builder`](example/code_builder_example.dart)
    - Shows how to build code programmatically using `package:code_builder`

<br>

- [`data_class_builder_example`](example/data_class_builder_example.dart)
    - combines both examples to generate a data class. 

    - In short, it takes this as an input:
    ```dart
    class Person  { 
    final String name;
    final String? nickname;
    final int age;
    final double height;
    final List<String> hobbies;
    }
    ```

    - To generate this as an output:
    <br><br>

    ```dart
    class Person {
    const Person({
        required this.name,
        this.nickname,
        required this.age,
        required this.height,
        required this.hobbies,
    });

    factory Person.fromMap(Map<String, dynamic> map) {
        return Person(
        name: map['name'],
        nickname: map['nickname'],
        age: map['age'].toInt(),
        height: map['height'].toDouble(),
        hobbies: List.from(map['hobbies']),
        );
    }

    factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

    final String name;

    final String? nickname;

    final int age;

    final double height;

    final List<String> hobbies;

    Person copyWith({
        String? name,
        String? nickname,
        int? age,
        double? height,
        List<String>? hobbies,
    }) {
        return Person(
        name: name ?? this.name,
        nickname: nickname ?? this.nickname,
        age: age ?? this.age,
        height: height ?? this.height,
        hobbies: hobbies ?? this.hobbies,
        );
    }

    String toJson() => json.encode(toMap());
    Map<String, dynamic> toMap() {
        return {
        'name': name,
        'nickname': nickname,
        'age': age,
        'height': height,
        'hobbies': hobbies,
        };
    }

    @override
    String toString() {
        return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies)';
    }

    @override
    bool operator ==(Object other) {
        if (identical(this, other)) return true;
        // TODO: handle list equality here
        return other is Person &&
            other.name == name &&
            other.nickname == nickname &&
            other.age == age &&
            other.height == height &&
            other.hobbies == hobbies;
    }

    @override
    int get hashCode {
        return name.hashCode ^ nickname.hashCode ^ age.hashCode ^ height.hashCode ^ hobbies.hashCode;
        }
    }

    ```

----

Disclimar: 
These examples were written (_poorly_) for learning purposes and to understand how these packages work together -- no more no less.   