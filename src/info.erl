%% @author Administrator
%% @doc @todo Add description to info.


-module(info).

%% ====================================================================
%% API functions
%% ====================================================================
-export([t/0]).
-include("head1.hrl").


%% ====================================================================
%% Internal functions
%% ====================================================================


t()->
  ?SHOW("[shell]              pid:~p~n",[self()]),
  ?SHOW("[app]                pid:~p~n",[whereis(?APPNAME)]),
  ?SHOW("[sup] for tree top   pid:~p~n",[whereis(?SUPTREENAME)]),
  ?SHOW("[server] core server pid:~p~n",[whereis(?SERVERNAME)]),
  ?SHOW("[Listen] listen proc pid:~p~n",[whereis(?CONNECTNAME)]),
  ?SHOW("[sup] for pre user   pid:~p~n",[whereis(?SUP_PREUSER_NAME)]),
  ?SHOW("[fsm] logger timer   pid:~p~n",[whereis(?LOGGERNAME)]),
  Link1=lists:keyfind(links, 1, process_info(whereis(?SUPTREENAME))),
  ?SHOW("[sup] for tree top,it links is:~p~n",[Link1]),
  Link2=lists:keyfind(links, 1, process_info(whereis(?SERVERNAME))),
  ?SHOW("[server] for core server,it links is:~p~n",[Link2]),
  Link3=lists:keyfind(links, 1, process_info(whereis(?SUP_PREUSER_NAME))),
  ?SHOW("[sup] for pre user,it links is:~p~n",[Link3]),
  ?SHOW("[search] look the connect count:~p~n",[myChatServer2:getConnectCount()]),
  ?SHOW("[search] look the login   count:~p~n",[myChatServer2:getLoginCount()]),
  ?SHOW("~p~n",[supervisor:which_children(?SUP_PREUSER_NAME)]).

