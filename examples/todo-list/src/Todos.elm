module Todos exposing (Index, Msg(..), State, addItem, inForm, init, setItems, update, view)

import Data.TodoItem exposing (TodoItem)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Todos.Form as Form
import Update.Deep exposing (..)


type alias Index =
    Int


type Msg
    = TodosFormMsg Form.Msg
    | MarkDone Index
    | Delete Index


type alias State =
    { items : List TodoItem
    , form : Form.State
    }


setItems : List TodoItem -> State -> Update State msg a
setItems items state =
    save { state | items = items }


addItem : TodoItem -> State -> Update State msg a
addItem item state =
    save { state | items = item :: state.items }


inForm : Wrap State Msg Form.State Form.Msg a
inForm =
    wrapState
        { get = .form
        , set = \state form -> { state | form = form }
        , msg = TodosFormMsg
        }


init : (Msg -> msg) -> Update State msg a
init toMsg =
    save State
        |> andMap (save [])
        |> andMap (Form.init TodosFormMsg)
        |> mapCmd toMsg


update : { onTaskAdded : TodoItem -> a, onTaskDone : TodoItem -> a } -> Msg -> State -> Update State Msg a
update { onTaskAdded, onTaskDone } msg =
    let
        handleSubmit data =
            let
                item =
                    { text = data.text }
            in
            addItem item
                >> andApplyCallback (onTaskAdded item)

        removeItem ix flags state =
            state
                |> (case List.drop ix state.items of
                        [] ->
                            save

                        item :: rest ->
                            setItems (List.take ix state.items ++ rest)
                                >> andWhen flags.notify (applyCallback <| onTaskDone item)
                   )
    in
    case msg of
        TodosFormMsg formMsg ->
            inForm (Form.update { onSubmit = handleSubmit } formMsg)

        MarkDone ix ->
            removeItem ix { notify = True }

        Delete ix ->
            removeItem ix { notify = False }


view : State -> (Msg -> msg) -> Html msg
view { items, form } toMsg =
    let
        indexed =
            List.indexedMap Tuple.pair

        row ( ix, todo ) =
            tr []
                [ td [ style "width" "180px" ]
                    [ span [ class "icon has-text-success" ]
                        [ i [ class "fa fa-check-square" ] [] ]
                    , a [ onClick (toMsg <| MarkDone ix), href "#" ]
                        [ text "Done" ]
                    , span
                        [ style "margin-left" ".5em"
                        , class "icon has-text-danger"
                        ]
                        [ i [ class "fa fa-trash" ] [] ]
                    , a [ onClick (toMsg <| Delete ix), href "#" ]
                        [ text "Delete" ]
                    ]
                , td []
                    [ text todo.text ]
                ]
    in
    div [ style "margin" "1em" ]
        [ Form.view form (toMsg << TodosFormMsg)
        , h3 [ class "title is-3" ] [ text "Tasks" ]
        , if List.isEmpty items then
            p [] [ text "You have no tasks" ]

          else
            table [ class "table is-narrow is-bordered is-fullwidth" ] (List.map row (indexed items))
        ]
