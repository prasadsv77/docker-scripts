->Run test cases with the following command:
mvn clean test

->Generate allure report:
allure serve <project folder>\target\surefire-reports

Installing allure CLI :-
----------------------
1-Make sure PowerShell 5 (or later, include PowerShell Core) and .NET Framework 4.5 (or later) are installed. Then run:
iwr -useb get.scoop.sh | iex

Note: if you get an error you might need to change the execution policy (i.e. enable Powershell) with
Set-ExecutionPolicy RemoteSigned -scope CurrentUser

2-Install allure:
scoop install allure

3-Check Installation:
allure --version

Reference:https://docs.qameta.io/allure/#_get_started