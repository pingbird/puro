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
