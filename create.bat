@echo off
echo create a project
echo please input the project name
set /p name="name:"
echo %name%>project.name
rebar create-app appid=%name%
pause