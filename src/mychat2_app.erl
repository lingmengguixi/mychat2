-module(mychat2_app).

-behaviour(application).
-include("head1.hrl").
%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
	register(?APPNAME, self()),
	?SHOW("I:[app] pid:~p run!~n",[self()]),
    mychat2_sup:start_link().

stop(_State) ->
    ok.
