@echo off
for /f %%i in (project.name) do set name=%%i
echo name:%name%
erl -pa ebin -sname local_node -setcookie "ericlw" -eval "application:start(%name%)"