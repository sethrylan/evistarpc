%% @author Wally Cash <wally.cash@gmail.com>
%% @copyright (C) 2010-2011, Wally Cash
%% @doc A collection of utilities to manipulate VistA data structures. 
%% @end
%%
%% This program is free software: you can redistribute it and/or modify     
%% it under the terms of the GNU Affero General Public License as           
%% published by the Free Software Foundation, either version 3 of the       
%% License, or (at your option) any later version.                          
%%                                                                         
%% This program is distributed in the hope that it will be useful,          
%% but WITHOUT ANY WARRANTY; without even the implied warranty of           
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
%% GNU Affero General Public License for more details.                      
%%                                                                         
%% You should have received a copy of the GNU Affero General Public License 
%% along with this program.  If not, see http://www.gnu.org/licenses/.


-module(evistarpc_util).  
-export([piece/2, piece/3, to_fm_date/1, to_fm_datetime/1, from_fm_datetime/1, to_record/2, to_json/1, to_json/2]).

-include("evistarpc.hrl").

%%--------------------------------------------------------------------
%% @doc Parses a \r\n delimited string to a key value record. Intended 
%% to populate Nitrogen combo/list boxes via the record syntax.
%% @end
%%--------------------------------------------------------------------

to_record(Rec, Str) ->	
	L=string:tokens(Str, "\r\n"),
	[Rec#listdata{key=piece(Y, 2),value=piece(Y, 1)} || Y <- L].

%%--------------------------------------------------------------------
%% @doc Parses a '\r\n' delimited string to JSON using teh default 
%% conversion. The array id will be set to "data" and elements will 
%% be parsed as 'key'-'value' pairs, with key parsed from the second
%% position and value from the first.
%% @end
%%--------------------------------------------------------------------
to_json(Str) ->
	to_json(Str, {[], []}).

%%--------------------------------------------------------------------
%% @doc Parses a '\r\n' delimited string to JSON with arguments specifying
%% the conversion. Arguments are passed as a tuple. The first 
%% element of the tuple is a string identifying the array and the second 
%% is a list of tuples specifying the element identifier and position. 
%% @end
%%--------------------------------------------------------------------
to_json(Str, {Id, Args}) ->
	case Args of 
	[] ->
		A=[{"key",2},{"value",1}];
	_ -> A=Args
	end,
	case Id of 
	[] ->
		T="data";
	_ -> T=Id
	end,
	L=string:tokens(Str, "\r\n"),
	J={struct, [{T,{array, [{struct,apply_args(A, Y)} || Y <- L]}}]},
	mochijson:encode(J).

apply_args(A, Y) ->
    apply_args1(A, Y, []).

apply_args1([H|T], Y, Acc) ->
	{K,V}=H,
	J={K, piece(Y, V)},
	apply_args1(T, Y, [J|Acc]);

apply_args1([], _Y, Acc)-> 
	lists:reverse(Acc).

%%--------------------------------------------------------------------
%% @doc Extracts an element from a '^' delimited list specified
%% by its position.
%% @end
%%--------------------------------------------------------------------

piece(Str, Pos) ->
    piece1(Str,Pos,1,"^",[]).

%%--------------------------------------------------------------------
%% @doc Extracts an element from a delimited list specified
%% by its position and delimiter.
%% @end
%%--------------------------------------------------------------------

piece(Str, Pos, Sep) ->
    piece1(Str, Pos, 1, Sep, []).

piece1([H|T], Pos, J, Sep, Acc) ->
    case lists:member(H, Sep) of
	true -> 
		case J=:=Pos of
		true ->		
			piece1([], Pos, J+1, Sep, Acc);
		false ->
			piece1(T, Pos, J+1, Sep, [])
		end;
	false -> 
		piece1(T, Pos, J, Sep, [H|Acc])
    end;

piece1([], _I, _J, _Sep, Acc)-> lists:reverse(Acc).

%%--------------------------------------------------------------------
%% @doc Converts an Erlang datetime tuple to fileman format.
%% @end
%%--------------------------------------------------------------------

to_fm_datetime(DateTime) ->
    {{Year,Month,Day},{Hour,Min,Sec}} = DateTime,
	Year2=Year-1700,
    D=io_lib:format("~3.10.0B~2.10.0B~2.10.0B.~2.10.0B~2.10.0B~2.10.0B",[Year2, Month, Day, Hour, Min, Sec]),
	lists:flatten(D).

%%--------------------------------------------------------------------
%% @doc Converts an Erlang date tuple to fileman format.
%% @end
%%--------------------------------------------------------------------
to_fm_date(Date) ->
    {Year,Month,Day}=Date,
	Year2=Year-1700,
    D=io_lib:format("~3.10.0B~2.10.0B~2.10.0B",[Year2, Month, Day]),
	lists:flatten(D).

%%--------------------------------------------------------------------
%% @doc Converts a fileman datetime string to a datetime tuple.
%% @end
%%--------------------------------------------------------------------
from_fm_datetime(DateTime) ->
	{Yr,_}=string:to_integer(string:sub_string(DateTime,1,3)),
	Year=Yr+1700,
	Mo=string:sub_string(DateTime,4,5),
	Da=string:sub_string(DateTime,6,7),
	Hr=string:sub_string(DateTime,9,10),
	Min=string:sub_string(DateTime,11,12),
	Sec=string:sub_string(DateTime,13,14),
	{{Year,Mo,Da},{Hr,Min,Sec}}.
