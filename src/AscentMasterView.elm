module AscentMasterView exposing (content)

import AscentMasters as AM exposing (CosmicRay)
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Locale


content : Locale.Locale -> Maybe CosmicRay -> Html msg
content locale maybeMaster =
    div [ class "place-self-center pt-3 box-content min-w-0 w-full" ]
        [ ascentMasterView locale maybeMaster ]


ascentMasterView : Locale.Locale -> Maybe CosmicRay -> Html msg
ascentMasterView locale maybeMaster =
    case maybeMaster of
        Nothing ->
            div [] []

        Just master ->
            div [ class "meuastral-masters" ]
                [ ascentMasterCard locale master
                , archangelCard locale master
                ]


ascentMasterCard : Locale.Locale -> CosmicRay -> Html msg
ascentMasterCard locale master =
    div [ class "card meuastral-master" ]
        [ H.span
            [ class "meuastral-ray-badge"
            , HA.style "background" (AM.color_name master)
            , HA.style "color" (badgeTextColor master)
            ]
            [ H.text ((Locale.copy locale).rayLabel ++ " " ++ AM.number master) ]
        , H.figure [ class "flex-col w-full" ]
            [ H.img
                [ class "meuastral-master-image"
                , HA.src (AM.master_image master)
                , HA.alt (AM.master_name_for locale master)
                , HA.width 512
                , HA.height 512
                , HA.attribute "loading" "lazy"
                , HA.attribute "decoding" "async"
                ]
                []
            , H.figcaption [ class "prose my-2 text-center text-lg font-medium" ]
                [ H.text (AM.master_name_for locale master) ]
            ]
        , H.hr [] []
        , div [ class "card-body" ]
            [ H.p [ class "prose w-fit" ] [ H.text (AM.master_details_for locale master) ]
            ]
        ]


badgeTextColor : CosmicRay -> String
badgeTextColor master =
    case AM.color_name master of
        "gold" ->
            "#1f2937"

        "pink" ->
            "#1f2937"

        "whitesmoke" ->
            "#1f2937"

        _ ->
            "#ffffff"


archangelCard : Locale.Locale -> CosmicRay -> Html msg
archangelCard locale master =
    let
        localizedCopy =
            Locale.copy locale
    in
    div [ class "card meuastral-master" ]
        [ H.figure [ class "flex-col w-full" ]
            [ H.img
                [ class "meuastral-master-image"
                , HA.src (AM.archangel_image master)
                , HA.alt (localizedCopy.archangelPrefix ++ AM.archangel_name_for locale master)
                , HA.width 512
                , HA.height 512
                , HA.attribute "loading" "lazy"
                , HA.attribute "decoding" "async"
                ]
                []
            , H.figcaption [ class "prose my-2 text-center text-lg font-medium" ]
                [ H.text (localizedCopy.archangelPrefix ++ AM.archangel_name_for locale master) ]
            ]
        , H.hr [] []
        , div [ class "card-body" ]
            [ H.p [ class "prose w-fit" ] [ H.text (AM.ray_details_for locale master) ]
            ]
        ]
