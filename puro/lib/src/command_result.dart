import 'dart:io';

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
  Iterable<CommandMessage> get messages {
    return [
      CommandMessage('$exception\n$stackTrace'),
      CommandMessage(
        'Puro crashed! Please file an issue at https://github.com/PixelToast/puro',
      ),
    ];
  }

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
            help!,
            type: CompletionType.failure,
          ),
        if (usage != null)
          CommandMessage(
            usage!,
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

class BasicMessageResult extends CommandResult {
  BasicMessageResult(
    String message, {
    this.success = true,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage(message, type: type)];

  BasicMessageResult.format(
    String Function(OutputFormatter format) message, {
    this.success = true,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage.format(message, type: type)];

  BasicMessageResult.list(
    this.messages, {
    this.success = true,
    this.model,
  });

  @override
  final bool success;
  @override
  final List<CommandMessage> messages;
  @override
  final CommandResultModel? model;
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

class CommandMessage {
  CommandMessage(String message, {this.type}) : message = ((format) => message);
  CommandMessage.format(this.message, {this.type});

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

/// Like [CommandResult] but thrown as an exception.
class CommandError implements Exception {
  CommandError(
    String message, {
    CompletionType? type,
    CommandResultModel? model,
    bool success = false,
  }) : result = BasicMessageResult(
          message,
          success: success,
          type: type,
          model: model,
        );

  CommandError.format(
    String Function(OutputFormatter format) message, {
    CompletionType? type,
    CommandResultModel? model,
    bool success = false,
  }) : result = BasicMessageResult.format(
          message,
          success: success,
          type: type,
          model: model,
        );

  CommandError.list(
    List<CommandMessage> messages, {
    CommandResultModel? model,
    bool success = false,
  }) : result = BasicMessageResult.list(
          messages,
          success: success,
          model: model,
        );

  final CommandResult result;

  @override
  String toString() => result.toString();
}

class UnsupportedOSError extends CommandError {
  UnsupportedOSError()
      : super('Unrecognized operating system: `${Platform.operatingSystem}`');
}
