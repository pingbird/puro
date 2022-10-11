import 'package:puro/cli.dart' as cli;
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) {
  Chain.capture(() {
    cli.main(args);
  });
}
