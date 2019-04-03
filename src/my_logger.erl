%% @author Administrator
%% @doc @todo Add description to logger.


-module(my_logger).
-behaviour(gen_fsm).
-export([init/1, one_state/2, one_state/3, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/1,changeTimeStyle/1,cancel/0,stop/0,lookup_time/0]).

-include("head1.hrl").

%% ====================================================================
%% Behavioural functions
%% ====================================================================
-record(state, {}).

%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:init-1">gen_fsm:init/1</a>
-spec init(Args :: term()) -> Result when
	Result :: {ok, StateName, StateData}
			| {ok, StateName, StateData, Timeout}
			| {ok, StateName, StateData, hibernate}
			| {stop, Reason}
			| ignore,
	StateName :: atom(),
	StateData :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================
init([TimeStyle]) ->
	io:format("I:[fsm] logger ~p run!~n",[self()]),
    Time=lookupNextTime(TimeStyle),
	Ref=gen_fsm:send_event_after(Time, nextEvent),
    {ok, one_state, {TimeStyle,Ref}}.


%% state_name/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:StateName-2">gen_fsm:StateName/2</a>
-spec one_state(Event :: timeout | term(), StateData :: term()) -> Result when
	Result :: {next_state, NextStateName, NewStateData}
			| {next_state, NextStateName, NewStateData, Timeout}
			| {next_state, NextStateName, NewStateData, hibernate}
			| {stop, Reason, NewStateData},
	NextStateName :: atom(),
	NewStateData :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================
% @todo implement actual state
one_state(nextEvent, {TimeStyle,_}) ->
	T={MegaSecs, Secs, MicroSecs}=os:timestamp(),
	Time_list=time2Lists(T),
	Now_time=MegaSecs*1000000000+Secs*1000+MicroSecs div 1000,
	Connect_num=myChatServer2:getConnectCount(),
	Login_num=myChatServer2:getLoginCount(),
	?SHOW("T:~p connect_num:~p login_num:~p ~n",[Time_list,Connect_num,Login_num]),
	mysql:fetch(p1, list_to_binary(["insert into logger_mychat values(",integer_to_list(Now_time),",",integer_to_list(Connect_num),",",integer_to_list(Login_num),")"])),
	NextTime=lookupNextTime(TimeStyle),
	Ref=gen_fsm:send_event_after(NextTime, nextEvent),
    {next_state, one_state, {TimeStyle,Ref}}.


%% state_name/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:StateName-3">gen_fsm:StateName/3</a>
-spec one_state(Event :: term(), From :: {pid(), Tag :: term()}, StateData :: term()) -> Result when
	Result :: {reply, Reply, NextStateName, NewStateData}
			| {reply, Reply, NextStateName, NewStateData, Timeout}
			| {reply, Reply, NextStateName, NewStateData, hibernate}
			| {next_state, NextStateName, NewStateData}
			| {next_state, NextStateName, NewStateData, Timeout}
			| {next_state, NextStateName, NewStateData, hibernate}
			| {stop, Reason, Reply, NewStateData}
			| {stop, Reason, NewStateData},
	Reply :: term(),
	NextStateName :: atom(),
	NewStateData :: atom(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: normal | term().
%% ====================================================================
one_state(Event, _From, StateData) ->
    Reply = ok,
	io:format("E:[logger] unknown event in one_state/3:~p~n",[Event]),
    {reply, Reply, one_state, StateData}.


%% handle_event/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:handle_event-3">gen_fsm:handle_event/3</a>
-spec handle_event(Event :: term(), StateName :: atom(), StateData :: term()) -> Result when
	Result :: {next_state, NextStateName, NewStateData}
			| {next_state, NextStateName, NewStateData, Timeout}
			| {next_state, NextStateName, NewStateData, hibernate}
			| {stop, Reason, NewStateData},
	NextStateName :: atom(),
	NewStateData :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================

handle_event({changeTimeStyle,New_TimeStyle}, StateName, {TimeStyle,Ref_before}) ->
	gen_fsm:cancel_timer(Ref_before),
    Time=lookupNextTime(TimeStyle),
	Ref=gen_fsm:send_event_after(Time, nextEvent),
    {next_state, StateName, {New_TimeStyle,Ref}};
handle_event(stop,_StateName, StateData) ->
	{stop, normal,StateData};
handle_event(cancel,StateName, {TimeStyle,Ref}) ->
	gen_fsm:cancel_timer(Ref),
    {next_state, StateName, {TimeStyle,undefined}};
handle_event(lookup_time,StateName, {TimeStyle,Ref}) ->
	case Ref of
	    undefined->io:format("remain time:undefined~n");
		Ref->T=lookupNextTime(TimeStyle),
             io:format("remain time:~pms~n",[T])
	end,
    {next_state, StateName, {TimeStyle,Ref}};
handle_event(Event, StateName, StateData) ->
	io:format("E:[logger] unkown event in handle_event:~p~n",[Event]),
    {next_state, StateName, StateData}.


%% handle_sync_event/4
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:handle_sync_event-4">gen_fsm:handle_sync_event/4</a>
-spec handle_sync_event(Event :: term(), From :: {pid(), Tag :: term()}, StateName :: atom(), StateData :: term()) -> Result when
	Result :: {reply, Reply, NextStateName, NewStateData}
			| {reply, Reply, NextStateName, NewStateData, Timeout}
			| {reply, Reply, NextStateName, NewStateData, hibernate}
			| {next_state, NextStateName, NewStateData}
			| {next_state, NextStateName, NewStateData, Timeout}
			| {next_state, NextStateName, NewStateData, hibernate}
			| {stop, Reason, Reply, NewStateData}
			| {stop, Reason, NewStateData},
	Reply :: term(),
	NextStateName :: atom(),
	NewStateData :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================
handle_sync_event(Event, From, StateName, StateData) ->
    Reply = ok,
    {reply, Reply, StateName, StateData}.


%% handle_info/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:handle_info-3">gen_fsm:handle_info/3</a>
-spec handle_info(Info :: term(), StateName :: atom(), StateData :: term()) -> Result when
	Result :: {next_state, NextStateName, NewStateData}
			| {next_state, NextStateName, NewStateData, Timeout}
			| {next_state, NextStateName, NewStateData, hibernate}
			| {stop, Reason, NewStateData},
	NextStateName :: atom(),
	NewStateData :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: normal | term().
%% ====================================================================
handle_info(Info, StateName, StateData) ->
    {next_state, StateName, StateData}.


%% terminate/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:terminate-3">gen_fsm:terminate/3</a>
-spec terminate(Reason, StateName :: atom(), StateData :: term()) -> Result :: term() when
	Reason :: normal
			| shutdown
			| {shutdown, term()}
			| term().
%% ====================================================================
terminate(Reason, StateName, StatData) ->
    ok.


%% code_change/4
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_fsm.html#Module:code_change-4">gen_fsm:code_change/4</a>
-spec code_change(OldVsn, StateName :: atom(), StateData :: term(), Extra :: term()) -> {ok, NextStateName :: atom(), NewStateData :: term()} when
	OldVsn :: Vsn | {down, Vsn},
	Vsn :: term().
%% ====================================================================
code_change(OldVsn, StateName, StateData, Extra) ->
    {ok, StateName, StateData}.


%% ====================================================================
%% Internal functions
%% ====================================================================

%% @doc
%% 改变不同时间点记录
%% 提供小时整点，分钟整点,秒级整点
%% @end
-spec changeTimeStyle(TimeStyle::timeStyle())->ok.

changeTimeStyle(TimeStyle)->
	 case is_timeStyle(TimeStyle) of
		 true->gen_fsm:send_all_state_event(?LOGGERNAME, {changeTimeStyle,TimeStyle});
		 false->{error,"badarg"}
	 end.

%% 开始启动日志
-spec start_link(TimeStyle::timeStyle())-> Result when 
		  Result::{ok,Pid} | ignore | {error,Error},
          Pid :: pid(),
          Error :: {already_started,Pid} | term().
start_link(TimeStyle) ->
	mysql:start_link(p1, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, fun(_, _, _, _) -> ok end),
    mysql:connect(p1, ?DB_HOST, undefined, ?DB_USER, ?DB_PASS, ?DB_NAME, true),
    mysql:fetch(p1, <<"create table if not exists logger_mychat(time long,connect_num long,login_num long) engine = InnoDB">>),
	 case is_timeStyle(TimeStyle) of
		 true->gen_fsm:start_link({local,?LOGGERNAME}, ?LOGGERMODULE, [TimeStyle], []);
		 false->{error,"badarg"}
	 end.

%% 终止fsm进程
stop()->
     gen_fsm:send_all_state_event(?LOGGERNAME, stop).

%% cancle当前的记录行为，但是不停止fsm进程
cancel()->
     gen_fsm:send_all_state_event(?LOGGERNAME, cancel).

%% 距离下一次记录的ms时间
lookup_time()->
	gen_fsm:send_all_state_event(?LOGGERNAME, lookup_time).


%% 内部函数
is_timeStyle(TimeStyle)->
	case TimeStyle of
		hour_sharp->true;
		minute_sharp->true;
		second_sharp->true;
		_->false
	end.

-spec lookupNextTime(TimeStyle::timeStyle())-> Remain_time::integer().
lookupNextTime(TimeStyle) ->
	{MegaSecs, Secs, MicroSecs}=os:timestamp(),
	Now_time=MegaSecs*1000000000+Secs*1000+MicroSecs div 1000,
	case TimeStyle of
		hour_sharp->
			Time=(3600000-(Now_time rem 3600000)) rem 3600000;
		minute_sharp->
            Time=(60000-(Now_time rem 60000)) rem 60000;
        second_sharp->
            Time=(1000-(Now_time rem 1000)) rem 1000
    end,Time.

time2Lists(Time)->
	 {{Year,Month,Day},{H,M,S}}=calendar:now_to_local_time(Time),
	 lists:concat([integer_to_list(Year),"-",integer_to_list(Month),"-",integer_to_list(Day),"  ",integer_to_list(H),":",integer_to_list(M),":",integer_to_list(S)]).