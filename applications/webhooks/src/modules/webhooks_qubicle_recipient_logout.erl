%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2020, 2600Hz
%%%
%%%
%%% @author Mark Magnusson
%%% @end
%%%-----------------------------------------------------------------------------
-module(webhooks_qubicle_recipient_logout).

-export([init/0
        ,bindings_and_responders/0
        ,handle/2
        ]).

-include_lib("webhooks/src/webhooks.hrl").

-define(QUBICLE_EVENT_EXCHANGE, <<"qubicle-event">>).
-define(QUBICLE_EVENT_EXCHANGE_TYPE, <<"topic">>).

-define(ID, kz_term:to_binary(?MODULE)).
-define(HOOK_NAME, <<"qubicle_recipient_logout">>).
-define(NAME, <<"Qubicle Recipient Logout">>).
-define(DESC, <<"Fires when a recipient logs out">>).
-define(METADATA
       ,kz_json:from_list([{<<"_id">>, ?ID}
                          ,{<<"name">>, ?NAME}
                          ,{<<"description">>, ?DESC}
                          ])
       ).

-spec init() -> 'ok'.
init() ->
    kapi_amqp_util:new_exchange(?QUBICLE_EVENT_EXCHANGE, ?QUBICLE_EVENT_EXCHANGE_TYPE),
    webhooks_util:init_metadata(?ID, ?METADATA).

-spec bindings_and_responders() -> {gen_listener:bindings(), gen_listener:responders()}.
bindings_and_responders() ->
    {[{'qubicle_recipient', ['event_only']}
     ]
    ,[{{?MODULE, 'handle'}
      ,[{<<"qubicle-recipient">>, <<"delete">>}
       ]
      }
     ]
    }.

-spec handle(kz_json:object(), kz_term:proplist()) -> 'ok'.
handle(JObj, _Props) ->
    AccountId = kz_json:get_value(<<"Account-ID">>, JObj),
    maybe_send_event(AccountId, format(JObj)).

-spec maybe_send_event(kz_term:api_binary(), kz_json:object()) -> 'ok'.
maybe_send_event('undefined', _JObj) -> 'ok';
maybe_send_event(AccountId, JObj) ->
    case webhooks_util:find_webhooks(?HOOK_NAME, AccountId) of
        [] -> lager:debug("no hooks to handle for ~s", [AccountId]);
        Hooks -> webhooks_util:fire_hooks(JObj, Hooks)
    end.

-spec format(kz_json:object()) -> kz_json:object().
format(JObj) ->
    RemoveKeys = [<<"Node">>
                 ,<<"Msg-ID">>
                 ,<<"App-Version">>
                 ,<<"App-Name">>
                 ,<<"Event-Category">>
                 ],
    kz_json:normalize_jobj(JObj, RemoveKeys, []).
