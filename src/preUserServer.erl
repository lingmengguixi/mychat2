%% @author Administrator
%% @doc @todo Add description to preUserServer.


-module(preUserServer).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3,logout/1,receiveFrom/3]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/1]).
-include("head1.hrl").


%% ====================================================================
%% Behavioural functions
%% ====================================================================
-record(state, {}).

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
init([Socket]) ->
    ?SHOW("I:[server] for pre user proc,pid:~p run!~n",[self()]),
	?SHOW("I:the socket is ~p~n",[Socket]),
	put(socket,Socket),
	put(loginState,false),
	myChatServer2:userConnect(self()),
    {ok, #state{}}.


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
handle_call(logout, _From, State) ->
	io:format("Formaxcfsdddddsssss~n"),
    Reply = ok,
	logout(),
    {reply, Reply, State};
handle_call(Request, From, State) ->
    Reply = ok,
	io:format("?????:~p~n",[Request]),
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

handle_info({tcp,Socket,Packet}, State) ->
	case Packet of
		<<?LOGINFLAG,IdLen:4,PasswLen:4,Id_binary:IdLen/binary,Passw_binary:PasswLen/binary>>->
			 Passw=binary_to_list(Passw_binary),
			 Id=binary_to_list(Id_binary),
			 case myChatServer2:login(Id, Passw, self()) of
				 {ok,Name,Last_login,Chat_times,Login_times}->?SHOW("I:[~p]login ok~n",[Id]),
					 put(loginState,true),
					 put(userid,Id),
					 TimeList=time2Lists(Last_login),
					 Chat_times_list=erlang:integer_to_list(Chat_times),
					 Login_times_list=erlang:integer_to_list(Login_times),
					 Respond=list_to_binary([?RESPOND_LOGIN,1,erlang:length(Name),erlang:length(TimeList),erlang:length(Chat_times_list),erlang:length(Login_times_list),Name,TimeList,Chat_times_list,Login_times_list]),
					 gen_tcp:send(Socket, Respond);
                 {false,Why}->
					 ?SHOW("I:[~p]login false:~p~n",[Id,Why]),
					 Respond=list_to_binary([?RESPOND_LOGIN,0,Why]),
					 gen_tcp:send(Socket, Respond)
			 end;
		<<?LOGOUTFLAG>>->
			logout();
		<<?SENDTOFLAG,Id_len,Id_binary:Id_len/binary,Msg_binary/binary>>->
			case get(loginState) of
				true->From=get(userid),
					  Id=binary_to_list(Id_binary),
					  Msg=binary_to_list(Msg_binary),
					  case myChatServer2:chatSendTo(From,Id,Msg) of
						  ok->gen_tcp:send(Socket, <<?RESPOND_SEND,1>>);
						  {false,Why}->
							    Respond=list_to_binary([?RESPOND_SEND,0,Why]),
							    gen_tcp:send(Socket, Respond)
					  end;
				false->
					Respond=list_to_binary([?RESPOND_SEND,0,"no login"]),
					gen_tcp:send(Socket, Respond)
			end;	
		<<?SENDTOALLFLAG,Msg/binary>>->
			case get(loginState) of
				true->From=get(userid),
					  myChatServer2:chatSendToAll(From, Msg),
					  gen_tcp:send(Socket, <<?RESPOND_SEND,1>>);
				false->gen_tcp:send(Socket, <<?RESPOND_SEND,0>>)
			end;
		<<?TESTID,Id_len,Id_binary:Id_len/binary>>->
			Id=binary_to_list(Id_binary),
			case myChatServer2:isUserExist(Id) of
				yes->Respond=list_to_binary([?RESPOND_TESTID,1,Id_len,Id]),
					 gen_tcp:send(Socket,Respond),
					 ?SHOW("I:test id[~p] yes!~n",[Id]);
				no->gen_tcp:send(Socket, <<?RESPOND_TESTID,0>>),
					 ?SHOW("I:test id[~p] no!~n",[Id])
			end;
		A->
			?SHOW("Id:receive len:~p packet:~p~n",[erlang:length(binary_to_list(Packet)),A]),
			ok
    end ,
    {noreply, State};
handle_info({tcp_closed,Socket}, State) ->
	case get(loginState) of
		true->logout();
		false->ok
	end,
    {stop, normal, State};
handle_info(stop,State)->
	logout(),
	{stop, normal, State};
handle_info(logout,State)->
	logout2(),
	{noreply, State};
handle_info({receiveFrom,From,Msg},State)->
    Socket=get(socket),
	case get(loginState) of
		true->
			Id=get(userid),
			?SHOW("I:[receive] from:~p to:~p msg:~p~n",[From,Id,Msg]),
			Len=erlang:length(From),
			gen_tcp:send(Socket, list_to_binary([?RESPOND_RECEIVE,Len,From,Msg])),
			{noreply, State};
		false->
			?SHOW("I:[receive] from:~p msg:~p   error:no login~n",[From,Msg]),
			{noreply, State}
	end;
handle_info(Info, State) ->
	io:format("Info[~p]:~p~n",[self(),Info]),
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
	?SHOW("I:[server] pre user proc,pid:~p stop!~n",[self()]),
	myChatServer2:userDisconnect(self()),
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


start_link(Socket)->
	Ans={ok,Pid}=gen_server:start_link(?PREUSER_MODULE, [Socket], []),
	Ans.

%% 远程暴力退出
logout(Pid)->
  %% gen_server:call(Pid, logout),      %不能使用这个，会死锁
    Pid!logout.

%% 用户发起退出
logout()->
	        Socket=get(socket),
  			UserId=get(userid),
             case get(loginState) of
                  true->put(loginState,false),
                        case myChatServer2:logout(UserId) of
                             ok->?SHOW("I:[~p]logout ok~n",[UserId]),
                                 gen_tcp:send(Socket, <<?RESPOND_LOGOUT,1>>);
                             {false,Why}->?SHOW("I:[~p]logout false:~p~n",[UserId,Why]),
                                 gen_tcp:send(Socket, list_to_binary([?RESPOND_LOGOUT,0,Why]))
                        end;
                  false->Why="user not login!",
                         gen_tcp:send(Socket, list_to_binary([?RESPOND_LOGOUT,0,Why])),
                         ?SHOW("I:[~p]logout false:~p~n",[UserId,Why])
             end.

%% 强制退出,由核心服务发起的退出
logout2()->
    Socket=get(socket),
	UserId=get(userid),
     case get(loginState) of
          true->put(loginState,false),
				?SHOW("I:[~p]logout ok with force~n",[UserId]),
				gen_tcp:send(Socket, <<?RESPOND_LOGOUT,2>>);
          false->?SHOW("I:error in my app")
     end.

%% 来自其他用户的消息,将消息推送给Pid进程
receiveFrom(From,Msg,Pid)->
    %% gen_server:call(?PREUSER_NAME, {receiveFrom,From,Msg}),    %不能使用这个，会死锁
	Pid!{receiveFrom,From,Msg}.

-spec time2Lists(Time::timestamp())->list().
time2Lists(Time)->
	 {{Year,Month,Day},{H,M,S}}=calendar:now_to_local_time(Time),
	 lists:concat([integer_to_list(Year),"-",integer_to_list(Month),"-",integer_to_list(Day),"  ",integer_to_list(H),":",integer_to_list(M),":",integer_to_list(S)]).