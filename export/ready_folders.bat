rmdir /s /q web
mkdir web
robocopy html\ web\ bg.png

rmdir /s /q win
mkdir win

rmdir /s /q linux
mkdir linux

rmdir /s /q mac
del /q *mac.zip*