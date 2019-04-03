%% @author Administrator
%% @doc @todo Add description to chatConnect.


-module(chatConnect).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/0]).
-include("head1.hrl").


%% ====================================================================
%% Internal functions
%% ====================================================================


start_link() ->
	
	Pid=erlang:whereis(?CONNECTNAME),
	if
		    Pid  =:= undefined->
			register(?CONNECTNAME, spawn_link(fun()->init() end));
		    true->{had_start,Pid}
	end.

init() ->
	?SHOW("I:[listen] listen pro,pid:~p run!~n",[self()]),
	{ok,Listen}=gen_tcp:listen(?PORT, [binary,{packet,4},{reuseaddr,true},{active,true}]),
    loop(Listen,1).

loop(Listen,I)->
	?SHOW("I:listen for [~p] ......~n",[I]),
    {ok,Socket}=gen_tcp:accept(Listen),
	?SHOW("I:new user[~p] connect~n",[I]),
	{ok,Pid}=supervisor:start_child(?SUP_PREUSER_NAME,[Socket]),
	ok=gen_tcp:controlling_process(Socket, Pid),
	loop(Listen,I+1).
