import '../models.dart';
import 'terminal.dart';

extension CommandResultModelExtensions on CommandResultModel {
  void addMessage(CommandMessage message, OutputFormatter format) {
    messages.add(
      CommandMessageModel(
        type: (message.type ??
                (success ? CompletionType.success : CompletionType.failure))
            .name,
        message: message.message(format),
      ),
    );
  }

  void addMessages(Iterable<CommandMessage> messages, OutputFormatter format) {
    for (final message in messages) {
      addMessage(message, format);
    }
  }
}

class CommandErrorResult extends CommandResult {
  CommandErrorResult(this.exception, this.stackTrace);

  final Object exception;
  final StackTrace stackTrace;

  @override
  CommandMessage get message =>
      CommandMessage((format) => '$exception\n$stackTrace');

  @override
  bool get success => false;

  @override
  CommandResultModel? get model => CommandResultModel(
        error: CommandErrorModel(
          exception: '$exception',
          exceptionType: '${exception.runtimeType}',
          stackTrace: '$stackTrace',
        ),
      );
}

class CommandHelpResult extends CommandResult {
  CommandHelpResult({
    required this.didRequestHelp,
    this.help,
    this.usage,
  });

  final bool didRequestHelp;
  final String? help;
  final String? usage;

  @override
  Iterable<CommandMessage> get messages => [
        if (message != null)
          CommandMessage(
            (format) => help!,
            type: CompletionType.failure,
          ),
        if (usage != null)
          CommandMessage(
            (format) => usage!,
            type: message == null && didRequestHelp
                ? CompletionType.plain
                : CompletionType.info,
          ),
      ];

  @override
  bool get success => didRequestHelp;

  @override
  CommandResultModel? get model => CommandResultModel(usage: usage);
}

class CommandMessage {
  CommandMessage(this.message, {this.type});
  final CompletionType? type;
  final String Function(OutputFormatter format) message;

  static String formatMessages({
    required Iterable<CommandMessage> messages,
    required OutputFormatter format,
    required bool success,
  }) {
    return messages
        .map((e) => format.complete(
              e.message(format),
              type: e.type ??
                  (success ? CompletionType.success : CompletionType.failure),
            ))
        .join('\n');
  }
}

abstract class CommandResult {
  bool get success;

  CommandMessage? get message => null;

  Iterable<CommandMessage> get messages => [message!];

  CommandResultModel? get model => null;

  CommandResultModel toModel([OutputFormatter format = plainFormatter]) {
    final result = CommandResultModel();
    if (model != null) {
      result.mergeFromMessage(model!);
    }
    result.success = success;
    result.addMessages(messages, format);
    return result;
  }

  @override
  String toString() => CommandMessage.formatMessages(
        messages: messages,
        format: plainFormatter,
        success: toModel().success,
      );
}

class BasicMessageResult extends CommandResult {
  BasicMessageResult({
    required this.success,
    required String message,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage((format) => message, type: type)];

  BasicMessageResult.format({
    required this.success,
    required String Function(OutputFormatter format) message,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage(message, type: type)];

  BasicMessageResult.list({
    required this.success,
    required this.messages,
    this.model,
  });

  @override
  final bool success;
  @override
  final List<CommandMessage> messages;
  @override
  final CommandResultModel? model;
}
