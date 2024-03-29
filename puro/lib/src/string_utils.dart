String escapePowershellString(String str) => str
    .replaceAll('`', '``')
    .replaceAll('"', '`"')
    .replaceAll('\$', '`\$')
    .replaceAll('\x00', '`0')
    .replaceAll('\x07', '`a')
    .replaceAll('\b', '`b')
    .replaceAll('\x1b', '`e')
    .replaceAll('\f', '`f')
    .replaceAll('\n', '`n')
    .replaceAll('\r', '`r')
    .replaceAll('\t', '`t')
    .replaceAll('\v', '`v');

String escapeCmdString(String str) => str
    .replaceAll('%', '%%')
    .replaceAll('&', '^&')
    .replaceAll('|', '^|')
    .replaceAll('<', '^<')
    .replaceAll('>', '^>')
    .replaceAll('(', '^(')
    .replaceAll(')', '^)')
    .replaceAll('!', '^^!')
    .replaceAll('"', '^"')
    .replaceAll("'", '^\'')
    .replaceAll('\x00', '^@')
    .replaceAll('\x07', '^G')
    .replaceAll('\b', '^H')
    .replaceAll('\x1b', '^[')
    .replaceAll('\f', '^L')
    .replaceAll('\n', '^J')
    .replaceAll('\r', '^M')
    .replaceAll('\t', '^I')
    .replaceAll('\v', '^K');
