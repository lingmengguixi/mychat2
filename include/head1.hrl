-define(APPNAME,mychat2).
-define(SERVERNAME,myChatServer2).
-define(SERVERMODULE,myChatServer2).
-define(CONNECTNAME,connect2).
-define(PORT,5656).
-define(EVENTNAME,myEvent).
-define(SUPTREENAME,mychat2_sup).
-define(SUP_PREUSER_NAME,preUserServer_sup).
-define(SUP_PREUSER_MODULE,preUserServer_sup).
-define(DEBUG,true).
-define(PREUSER_NAME,preUserServer).
-define(PREUSER_MODULE,preUserServer).
-define(LOGGERMODULE,my_logger).
-define(LOGGERNAME,my_logger).
-define(HOST,"127.0.0.1").
-define(LOGINFLAG,101).
-define(LOGOUTFLAG,102).
-define(SENDTOFLAG,103).
-define(SENDTOALLFLAG,104).
-define(TESTID,105).
-define(RESPOND_LOGIN,201).
-define(RESPOND_LOGOUT,202).
-define(RESPOND_SEND,203).
-define(RESPOND_RECEIVE,204).
-define(RESPOND_TESTID,205).

%% mysql
-define(DB_HOST, "localhost").
-define(DB_PORT, 3306).
-define(DB_USER, "root").
-define(DB_PASS, "1254677754").
-define(DB_NAME, "mydb").

-record(user, {
	     id           %% 用户id
        ,name   	 %% 用户名称
        ,passwd="123456" 	 %% 用户登录密码
        ,login_times=0 %% 登录次数
        ,chat_times=0  %% 聊天次数
        ,last_login=now()  %% 最后一次登录时间
        ,islogin=false        %%记录当前用户是否登陆
        ,pid=undefined        %%记录当前用户的pid进程
    }
).
 

%% 定义debug模式
-ifdef(DEBUG).
-ifndef(DEBUG_).
-define(DEBUG_,true).
-define(SHOW(A),io:format("~p~n",[A])).
-define(SHOW(A,B),io:format(A,B)).
-endif.
-else.
-define(SHOW(A),ok).
-define(SHOW(A,B),ok).
-endif.
%% 时间戳类型
-type timestamp() :: {MegaSecs :: non_neg_integer(),
                      Secs :: non_neg_integer(),
                      MicroSecs :: non_neg_integer()}.
-type timeStyle() ::hour_sharp|minute_sharp|second_sharp.