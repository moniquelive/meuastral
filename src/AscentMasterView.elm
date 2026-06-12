module AscentMasterView exposing (content)

import AscentMasters as AM exposing (CosmicRay)
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Locale


content : Locale.Locale -> Maybe CosmicRay -> Html msg
content locale maybeMaster =
    div [ class "place-self-center pt-3 box-content" ]
        [ ascentMasterView locale maybeMaster ]


ascentMasterView : Locale.Locale -> Maybe CosmicRay -> Html msg
ascentMasterView locale maybeMaster =
    case maybeMaster of
        Nothing ->
            div [] []

        Just master ->
            div [ class "flex justify-center flex-wrap py-4 gap-4 lg:gap-3" ]
                [ ascentMasterCard locale master
                , archangelCard locale master
                ]


ascentMasterCard : Locale.Locale -> CosmicRay -> Html msg
ascentMasterCard locale master =
    div [ class "indicator card w-80 lg:w-2/5 bg-base-100 shadow-xl" ]
        [ H.span
            [ class "indicator-item indicator-start py-6 badge badge-lg text-4xl text-white font-bold"
            , HA.style "background" (AM.color_name master)
            ]
            [ H.text (AM.number master) ]
        , H.figure [ class "flex-col w-full" ]
            [ H.img [ class "rounded ring", HA.src (AM.master_image master) ] []
            , H.figcaption [ class "prose my-2 text-center text-lg font-medium" ]
                [ H.text (AM.master_name_for locale master) ]
            ]
        , H.hr [] []
        , div [ class "card-body" ]
            [ H.p [ class "prose w-fit" ] [ H.text (AM.master_details_for locale master) ]
            ]
        ]


archangelCard : Locale.Locale -> CosmicRay -> Html msg
archangelCard locale master =
    let
        localizedCopy =
            Locale.copy locale
    in
    div [ class "card w-80 lg:w-2/5 bg-base-100 shadow-xl" ]
        [ H.figure [ class "flex-col w-full" ]
            [ H.img [ class "rounded ring", HA.src (AM.archangel_image master) ] []
            , H.figcaption [ class "prose my-2 text-center text-lg font-medium" ]
                [ H.text (localizedCopy.archangelPrefix ++ AM.archangel_name_for locale master) ]
            ]
        , H.hr [] []
        , div [ class "card-body" ]
            [ H.p [ class "prose w-fit" ] [ H.text (AM.ray_details_for locale master) ]
            ]
        ]
