$puro_version = ..\..\puro\bin\puro.exe version --plain
&"C:\Program Files (x86)\Inno Setup 6\iscc" "/dAppVersion=${puro_version}" install.iss