
-module(mychat2_sup).

-behaviour(supervisor).
-include("head1.hrl").
%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?SUPTREENAME}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
	?SHOW("I:[sup] for tree top,pid:~p run!~n",[self()]),
	AChild_core_server = {?SERVERNAME, {?SERVERMODULE, start_link, []}, permanent,infinity, worker, [?SERVERMODULE]},
	BChild_sup = {?SUP_PREUSER_NAME,{?SUP_PREUSER_MODULE,start_link,[]},permanent,infinity,worker,[?SUP_PREUSER_MODULE]},
	CChild_logger = {?LOGGERNAME,{?LOGGERMODULE,start_link,[minute_sharp]},permanent,infinity,worker,[?LOGGERMODULE]},
    A={ok, { {one_for_one, 1, 10}, [AChild_core_server,BChild_sup,CChild_logger]}}
    ,A.
