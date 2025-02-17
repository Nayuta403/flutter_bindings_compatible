import 'dart:io';

bool removeOriginDependency = false;
RegExp regExp = RegExp(
    r'(Scheduler|Widgets|Gesture|Renderer|Services|Painting|Semantics)Binding.instance(\!|\?)');

void main(List<String> arguments) async {
  Directory currentProject = Directory.current;
  if (arguments.contains('-remove')) removeOriginDependency = true;

  String libPath = '${currentProject.path}/lib';
  handlePath(libPath);
}

Future<void> handlePath(String path) async {
  if (await FileSystemEntity.isFile(path)) await handleCodeFile(path);
  if (await FileSystemEntity.isDirectory(path)) {
    Directory dir = Directory(path);
    if (await dir.exists()) {
      var list = dir.listSync();
      for (var element in list) {
        await handlePath(element.path);
      }
    }
  }
}

Future<void> handleCodeFile(String path) async {
  if (path.contains('.dart')) {
    File file = File(path);
    bool hasMatched = false;
    List<String> codes = await file.readAsLines();
    for (int i = 0; i < codes.length; i++) {
      codes[i] = codes[i].replaceAllMapped(regExp, (match) {
        hasMatched = true;
        String? binding;
        try {
          binding = 'use${match[0]?.split('.')[0]}()'.replaceAll(' ', '');
        } catch (e) {
          binding = match.input;
        }
        return binding;
      });
    }
    if (hasMatched) {
      codes.insert(1,
          'import \'package:bindings_compatible/bindings_compatible.dart\';');
      if (removeOriginDependency) {
        codes.remove('import \'package:flutter/gestures.dart\';');
        codes.remove('import \'package:flutter/rendering.dart\';');
        codes.remove('import \'package:flutter/scheduler.dart\';');
        codes.remove('import \'package:flutter/services.dart\';');
        codes.remove('import \'package:flutter/widgets.dart\';');
      }

      file.writeAsString(join(codes, '\n'));
    }
  }
}

String join(List<String> sources, String separator) {
  if (sources.isEmpty) return "";
  StringBuffer buffer = StringBuffer();
  for (int i = 0; i < sources.length; i++) {
    buffer.write(sources[i]);
    if (i != sources.length) buffer.write(separator);
  }
  return buffer.toString();
}
