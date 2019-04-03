 %% @author Administrator
%% @doc @todo Add description to chatClient.


-module(chatClient).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).
-include("head1.hrl").
-define(RECEIVEPROCESS,receiveProcess).
-define(CONSOLEPROCESS,consoleProcess).

%% ====================================================================
%% Internal functions
%% ====================================================================


start()->
   connectNet().

connectNet()->
   case gen_tcp:connect(?HOST, ?PORT, [binary,{packet,4}]) of
	    {ok,Socket}->
			io:format("find the server ok!~n"),
			Pid=self(),
			UserReceive=spawn_link(fun()->startRecive(Socket) end),
			put(receiveProcess,UserReceive),
			register(?RECEIVEPROCESS,UserReceive),
			register(?CONSOLEPROCESS,self()),
			gen_tcp:controlling_process(Socket, UserReceive),
			put(tip,"no login"),
			put(loginState,false),
			put(user,undefined),
			put(chatUser,"ALL"),
			erlang:process_flag(trap_exit, true),
		    command(Socket);
	    {error,econnrefused}->
			  io:format("cannot connect the network!~n");
	    Args->io:format("cannot connect the network!~ncause:~p~n",[Args])
   end.

%% 接收服务端消息的进程
startRecive(Socket)->
	receive
		{tcp,Socket,List}->
			case List of
			    <<?RESPOND_LOGIN,1,Name_len,Time_len,Chat_len,Login_len,Name_binary:Name_len/binary,Time_binary:Time_len/binary,Chat_times_binary:Chat_len/binary,Login_times_binary:Login_len/binary>> ->
					Name=binary_to_list(Name_binary),
					Time=binary_to_list(Time_binary),
					Chat_times=binary_to_list(Chat_times_binary),
					Login_times=binary_to_list(Login_times_binary),
                    ?CONSOLEPROCESS!{loginresult,ok,Name,Time,Chat_times,Login_times};
                <<?RESPOND_LOGIN,0,Why_binary/binary>>->
					Why=binary_to_list(Why_binary),
                    ?CONSOLEPROCESS!{loginresult,false,Why};
				<<?RESPOND_TESTID,0>>->
					?CONSOLEPROCESS!{testId_result,0};
				<<?RESPOND_TESTID,1,Id_len,Id_binary:Id_len/binary>>->
					Id=binary_to_list(Id_binary),
					?CONSOLEPROCESS!{testId_result,1,Id};	
				<<?RESPOND_LOGOUT,0,Why_binary/binary>>->
					Why=binary_to_list(Why_binary),
					?CONSOLEPROCESS!{logout_result,0,Why};
				<<?RESPOND_LOGOUT,1>>->
					?CONSOLEPROCESS!{logout_result,1};
				<<?RESPOND_LOGOUT,2>>->
					?CONSOLEPROCESS!{logout_result,2};
				<<?RESPOND_SEND,0,Why_binary/binary>>->
					Why=binary_to_list(Why_binary),
					?CONSOLEPROCESS!{send_result,0,Why};
				<<?RESPOND_SEND,1>>->
					?CONSOLEPROCESS!{send_result,1};
				<<?RESPOND_RECEIVE,From_len,From_binary:From_len/binary,Msg_binary/binary>>->
					Msg=binary_to_list(Msg_binary),
					From=binary_to_list(From_binary),
					case get(writeStatus) of
						true->
                              ?CONSOLEPROCESS!{receive_message,From,Msg};
						false->
							showMessage(From,Msg);
						undefined->
							put(writeStatus,false),
							showMessage(From,Msg)
					end;
                <<Respone/binary>>->
			        ?SHOW("respone:~p~n",[Respone])
			end,
			startRecive(Socket);
		{tcp_closed,Socket}->
			io:format("I:the connect closed!~n"),
			exit("connect close");		
		{writing}->
			put(writeStatus,true),
			startRecive(Socket);
		{writed}->
			put(writeStatus,false),
			startRecive(Socket)
	end.

command(Socket)->
  receive
		{'EXIT',RePid,Why}->
			io:format("exit:~p~n",[Why]),
			init:stop();
	    {receive_message,From,Msg}->
			showMessage(From,Msg),
			command(Socket);
	    {logout_result,2}->
			put(loginState,false),
			io:format("you user had force logout!~n"),
			command(Socket)
  after 0->
	   User=get(user),
	   case get(loginState) of
		  true->ChatUser=get(chatUser),
				
	            Tip=lists:concat([User,"->",ChatUser,">>"]);
		  false->Tip=lists:concat(["no login",">>"])
	   end,	
	   Command=io:get_line(Tip),
       case Command of
			  "login\n"->
				  case get(loginState) of
					  true->
						  io:format("had login:~p~n",[User]);
					  false->
			              Id=readLineWithoutLineFlag('user id:'),
			              Password=readLineWithoutLineFlag('user password:'),
						  Id_len=erlang:length(Id),
						  Passwd_len= erlang:length(Password),
						  
						  if
							  Id_len>15->
								  io:format("id error:must less than 15"),
								  command(Socket);
							  Passwd_len>15->
								  io:format("password error:must less than 15"),
								  command(Socket);
							  true->
								  Len=Id_len*16+Passwd_len,
								  Request=list_to_binary([?LOGINFLAG,Len,Id,Password]),
					              gen_tcp:send(Socket,Request),
								  receive 
									  {loginresult,ok,Name,Last_login,Chat_times,Login_times}->
										  io:format("I:login success!hi,~p   the last login time:~p~n",[Name,Last_login]),
					                      io:format("login times:~p~n",[Login_times]),
					                      io:format("chat times:~p~n",[Chat_times]),
										  put(user,Name),
									      put(last_login,Last_login),
										  put(chat_times,Chat_times),
										  put(login_times,Login_times),
										  put(loginState,true);
									  {loginresult,false,Why}->
										  io:format("login false,cause:~p~n",[Why])
								  after 6000->
									  io:format("E:time out!the server not response~n")
								  end
						  end
				  end,
					  command(Socket);
				  "to\n"->
                        Id=readLineWithoutLineFlag('user id:'),
						Id_len=erlang:length(Id),
						if
							Id_len>15->
								  io:format("id error:must less than 15");
							Id=:="ALL";Id=:="all"->
								  put(chatUser,"ALL");
							true->
								Request=[?TESTID,Id_len,Id],
								gen_tcp:send(Socket,list_to_binary(Request)),
								receive 
									{testId_result,0}->
										io:format("id not exist!~n");
									{testId_result,1,Id}->
										put(chatUser,Id)
								after 6000->
									io:format("E:time out!the server not response~n")
                                end
						end,
                        command(Socket);
		          "logout\n"->
					    case get(loginState) of
							true->
								Request=list_to_binary([?LOGOUTFLAG]),
								gen_tcp:send(Socket, Request),
								receive
									{logout_result,0,Why}->
										io:format("fail to logout!~ncause:~p~n",[Why]);
									{logout_result,1}->
										io:format("success to logout~n"),
										put(loginState,false)
								after 6000->
									io:format("E:time out!the server not response~n")
								end;
							false->
								io:format("no login~n")
						end,
						command(Socket);
				  "exit\n"->
					    io:format("exit!~n");
		          "send\n"->
					     ?RECEIVEPROCESS!{writing},
						 Message=getWriteMessage([]),
						 Id=get(chatUser),
						 case Id of
							 "ALL"-> Request=list_to_binary([?SENDTOALLFLAG,Message]);
							 Id -> Request=list_to_binary([?SENDTOFLAG,erlang:length(Id),Id,Message])
						 end,
				         gen_tcp:send(Socket, Request),
						 receive
							 {send_result,1}->
								 io:format("send ok!~n");
							 {send_result,0,Why}->
								 io:format("send false!~ncause:~p~n",[Why])
						 after 6000->
							 io:format("E:time out!the server not response~n")
						 end,
						 ?RECEIVEPROCESS!{writed},
						 command(Socket);
			  "help\n"-> io:format("the command list:~n"),
				  io:format("command:login~n"),
				  io:format("        use the id and password to login~n"),
				  io:format("command:logout~n"),
				  io:format("        if you had login,it will logout!~n"),
				  io:format("command:exit~n"),
				  io:format("        exit the client!~n"),
				  io:format("command:send~n"),
				  io:format("        write the message!~n"),
                  io:format("        use ..,it will stop writing the message and send the message!~n"),
				  io:format("command:to~n"),
				  io:format("        change the user who chat with you!~n"),
				  command(Socket);
		      "\n"->
				  command(Socket);
			  _->io:format("please use the command [help] to get the help~n"),
				  command(Socket)
			  end
      end.


%% 从标准输入获取message
getWriteMessage(Temp)->
	S=readLineWithoutLineFlag('writing:'),
	case S of
		".."->lists:concat(lists:reverse(Temp));
		_->getWriteMessage([[$\n],S|Temp])
	end.

%% 从控制台获取字符串，该字符串没有换行标志符
readLineWithoutLineFlag(Tip)->
   S=io:get_line(Tip),
   [$\n|S1]=lists:reverse(S),
   lists:reverse(S1).   

%% 从控制台获取一行数字
readIntegreLineWithoutLineFlag(Tip)->
	String=readLineWithoutLineFlag(Tip),
    try erlang:list_to_integer(String) of
        Int ->Int
    catch
        A:B->
        error
    end.

%% 显示消息
showMessage(From,Msg)->
   io:format("[Message] from ~p:~p~n",[From,Msg]).