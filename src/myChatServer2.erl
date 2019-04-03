%% @author Administrator
%% @doc @todo Add description to myChatServer2.


-module(myChatServer2).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3,chatSendTo/3]).
-include("head1.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([isUserExist/1,login/3,logout/1,start_link/0,stop/0,start_listen_process/0,userConnect/1,userDisconnect/1,getConnectCount/0,getLoginCount/0,chatSendToAll/2]).



%% ====================================================================
%% Behavioural functions
%% ====================================================================

%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:init-1">gen_server:init/1</a>
-spec init(Args :: term()) -> Result when
	Result :: {ok, State}
			| {ok, State, Timeout}
			| {ok, State, hibernate}
			| {stop, Reason :: term()}
			| ignore,
	State :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
init([]) ->
	%% io:format("I:the core server[~p] run~n",[self()]),
    ?SHOW("I:[server] core server,pid:~p run!~n",[self()]),
	Dict=dict:new(),
	Ids=["1001","1002","1003","1004","1005"],
	Names=["haha1","haha2","haha3","haha4","haha5"],
	UserMessage=createUserMessage(Ids, Names),
	Dict1=store(UserMessage,Dict),
	Dict2=store([{connectCount,0},{loginCount,0}],Dict1),
    {ok,Dict2}.

createUserMessage([],_)->
	[];
createUserMessage([Id|T1],[Name|T2])->
	Value={{user,Id},#user{name=Name,id=Id}},
    [Value|createUserMessage(T1,T2)].

store([],Dict)->
	Dict;
store([{Key,Value}|T],Dict)->
	Dict1=dict:store(Key, Value, Dict),
	store(T,Dict1).

%% handle_call/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_call-3">gen_server:handle_call/3</a>
-spec handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: term()) -> Result when
	Result :: {reply, Reply, NewState}
			| {reply, Reply, NewState, Timeout}
			| {reply, Reply, NewState, hibernate}
			| {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason, Reply, NewState}
			| {stop, Reason, NewState},
	Reply :: term(),
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================
handle_call({listen_process,start},_From,Dict)->
	Reply=chatConnect:start_link(),
	{reply,Reply,Dict};
handle_call(stop,_From,Dict)->
	{stop, normal, Dict};
handle_call({isUserExist,Id},_From,Dict)->
	case dict:find({user,Id},Dict) of
		error->Reply=no,
			   {reply,Reply,Dict};
		{ok,_}->Reply=yes,
                {reply,Reply,Dict}
	end;
handle_call({login,Id,Password,Pid},_From,Dict)->
	Ans=dict:find({user,Id}, Dict),
	case Ans of
		{ok,#user{passwd=Password,islogin=LoginState,pid=BeforePid}=User}->
			      
				  case LoginState of
					  true when Pid =/= BeforePid->preUserServer:logout(BeforePid),
						  Reply= {ok,User#user.name,User#user.last_login,User#user.chat_times,User#user.login_times},
						  NewDict=dict:update({user,Id}, fun(Value)-> Value#user{islogin=true,pid=Pid,login_times=Value#user.login_times+1,last_login=now()} end, Dict),
						  {reply,Reply,NewDict}; 
					  true ->
						  Reply= {ok,User#user.name,User#user.last_login,User#user.chat_times,User#user.login_times},
						  NewDict=dict:update({user,Id}, fun(Value)-> Value#user{islogin=true,pid=Pid,login_times=Value#user.login_times+1,last_login=now()} end, Dict),
						  {reply,Reply,NewDict}; 
					  false->
						  Reply= {ok,User#user.name,User#user.last_login,User#user.chat_times,User#user.login_times},
						  Dict1=dict:update({user,Id}, fun(Value)-> Value#user{islogin=true,pid=Pid,login_times=Value#user.login_times+1,last_login=now()} end, Dict),
	                      NewDict=dict:update(loginCount, fun(Value)-> Value+1 end, Dict1),
						  {reply,Reply,NewDict}
				  end;	  		
         _      ->Reply= {false,"password not Correct or id not exist"},
				  {reply,Reply,Dict}
    end;
handle_call({logout,Id},_From,Dict)->
	Ans=dict:find({user,Id}, Dict),
	case Ans of
		{ok,#user{islogin=false}}->
			          Reply={false,"the user had exit"},
				      {reply,Reply,Dict};
		{ok,#user{islogin=true}} ->
			Reply=ok,
	        Dict1=dict:update({user,Id}, fun(Value)-> Value#user{islogin=false} end, Dict),
	        NewDict=dict:update(loginCount, fun(Value)-> Value-1 end, Dict1),
	        {reply,Reply,NewDict};
		error->
			Reply={false,"the user not exist"},
			{reply,Reply,Dict}
	end;
handle_call({connect,_Pid}, _From, Dict) ->
	Dict1=dict:update(connectCount, fun(Value)-> Value+1 end, Dict),
    Reply=ok,
    {reply,Reply,Dict1};
handle_call({disconnect,_Pid}, _From, Dict) ->
	Dict1=dict:update(connectCount, fun(Value)-> Value-1 end, Dict),
    Reply=ok,
    {reply,Reply,Dict1};
handle_call({get,connectCount}, _From, Dict) ->
    {ok,Reply}=dict:find(connectCount, Dict),
    {reply,Reply,Dict};
handle_call({get,loginCount}, _From, Dict) ->
    {ok,Reply}=dict:find(loginCount, Dict),
    {reply,Reply,Dict};

handle_call({chatSendToAll,From,Msg}, _From, Dict) ->
	Childs=supervisor:which_children(?SUP_PREUSER_NAME),
	Reply=sendToAll(From, Childs, Msg),
	Dict1=dict:update({user,From}, fun(Value)-> Value#user{chat_times=Value#user.chat_times+1} end, Dict),
    {reply,Reply,Dict1};
handle_call({chatSendTo,From,To,Msg}, _From, Dict) ->
	{ok,User}=dict:find({user,To}, Dict),
	case User#user.pid of
       undefined->
		   Reply={false,"Other party no login"},
		   {reply,Reply,Dict};
	   Pid->preUserServer:receiveFrom(From, Msg, Pid),
			Reply=ok,
			Dict1=dict:update({user,From}, fun(Value)-> Value#user{chat_times=Value#user.chat_times+1} end, Dict),
			{reply,Reply,Dict1}
	end;
handle_call(Request, _From, State) ->
    Reply = ok,
	?SHOW("I:~p call Request:~p~n",[?MODULE,Request]),
    {reply, Reply, State}.


%% handle_cast/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_cast-2">gen_server:handle_cast/2</a>
-spec handle_cast(Request :: term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
handle_cast({'DOWN',_,process,Pid,Why}, Dict) ->
	Dict1=dict:update(connectCount, fun(Value)-> Value-1 end, Dict),
	?SHOW("I:disconnect [~p]~n",[Pid]),
    {noreply, Dict1};
handle_cast(Msg, State) ->
    {noreply, State}.


%% handle_info/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_info-2">gen_server:handle_info/2</a>
-spec handle_info(Info :: timeout | term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
handle_info(Info, State) ->
    {noreply, State}.


%% terminate/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:terminate-2">gen_server:terminate/2</a>
-spec terminate(Reason, State :: term()) -> Any :: term() when
	Reason :: normal
			| shutdown
			| {shutdown, term()}
			| term().
%% ====================================================================
terminate(Reason, State) ->
	?SHOW("I:the core server stop!"),
    ok.


%% code_change/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:code_change-3">gen_server:code_change/3</a>
-spec code_change(OldVsn, State :: term(), Extra :: term()) -> Result when
	Result :: {ok, NewState :: term()} | {error, Reason :: term()},
	OldVsn :: Vsn | {down, Vsn},
	Vsn :: term().
%% ====================================================================
code_change(OldVsn, State, Extra) ->
    {ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================



%% 有关客户端的网络连接数
userConnect(Pid)->
	gen_server:call(?SERVERNAME, {connect,Pid}).

userDisconnect(Pid)->
	gen_server:call(?SERVERNAME, {disconnect,Pid}).

getConnectCount()->
	gen_server:call(?SERVERNAME, {get,connectCount}).

%% 用户的登陆与退出操作
-spec login(Id::list(),Password::list(),Pid::pid())->{ok,Name::list(),Last_login::timestamp(),Chat_times::integer(),Login_times::integer()}|{false,Why::list()}.
login(Id,Password,Pid)->
	now(),
  gen_server:call(?SERVERNAME, {login,Id,Password,Pid}).

-spec logout(Id::list())->ok|{false,Why::list()} .
logout(Id)->
  gen_server:call(?SERVERNAME, {logout,Id}).

getLoginCount()->
  gen_server:call(?SERVERNAME, {get,loginCount}).

%% 服务启动与终止
stop()->
   gen_server:call(?SERVERNAME, stop).

start_link()->
  A=gen_server:start_link({local,?SERVERNAME}, ?SERVERMODULE, [], []),
  start_listen_process(),
  A.

%% 用户操作
-spec isUserExist(Id::list())->yes|no.
isUserExist(Id) when is_list(Id)->
   gen_server:call(?SERVERNAME, {isUserExist,Id}).

-spec chatSendTo(From::list(),To::list(),Msg::list())->ok|{false,Why::list()}.
chatSendTo(From,To,Msg) when is_list(From),is_list(To),is_list(Msg)->
  gen_server:call(?SERVERNAME, {chatSendTo,From,To,Msg}).

-spec chatSendToAll(From::list(),Msg::list())->integer().
chatSendToAll(From,Msg)->
	gen_server:call(?SERVERNAME, {chatSendToAll,From,Msg}).

%% 服务内部函数
start_listen_process()->
	gen_server:call(?SERVERNAME, {listen_process,start}).

-spec sendToAll(_From::list(),Childs::list(),Msg::list())->integer().
sendToAll(_From,[],_Msg)->
	0;
sendToAll(From,[{undefined,Pid,worker,[?PREUSER_MODULE]}|Childs],Msg)->
	preUserServer:receiveFrom(From, Msg, Pid),sendToAll(From,Childs,Msg)+1.