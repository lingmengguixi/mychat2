%% @author Administrator
%% @doc @todo Add description to preUserServer_sup.


-module(preUserServer_sup).
-behaviour(supervisor).
-export([init/1]).
-include("head1.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/0]).



%% ====================================================================
%% Behavioural functions
%% ====================================================================

%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/supervisor.html#Module:init-1">supervisor:init/1</a>
-spec init(Args :: term()) -> Result when
	Result :: {ok, {SupervisionPolicy, [ChildSpec]}} | ignore,
	SupervisionPolicy :: {RestartStrategy, MaxR :: non_neg_integer(), MaxT :: pos_integer()},
	RestartStrategy :: one_for_all
					 | one_for_one
					 | rest_for_one
					 | simple_one_for_one,
	ChildSpec :: {Id :: term(), StartFunc, RestartPolicy, Type :: worker | supervisor, Modules},
	StartFunc :: {M :: module(), F :: atom(), A :: [term()] | undefined},
	RestartPolicy :: permanent
				   | transient
				   | temporary,
	Modules :: [module()] | dynamic.
%% ====================================================================
init([]) ->
	?SHOW("I:[sup] for pre user process[~p] run!~n",[self()]),
    AChild = {?PREUSER_NAME, {?PREUSER_MODULE, start_link, []},temporary, 600000, worker, [?PREUSER_MODULE]},
    {ok, {{simple_one_for_one, 0, 1},[
									   AChild
									 ]}}.

%% ====================================================================
%% Internal functions
%% ====================================================================

start_link()->
   supervisor:start_link({local,?SUP_PREUSER_NAME}, ?SUP_PREUSER_MODULE, []).
