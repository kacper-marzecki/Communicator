module Info exposing (..)

import Browser
import Html exposing (Html, a, div, h1, i, img, input, li, nav, ol, p, td, text, tr, ul)
import Html.Attributes exposing (attribute, class, src, title)
import Terms exposing (..)


infoView : TermsLanguage -> Html msg
infoView language =
    let
        terms =
            getTerms language
    in
    div [ class "container" ]
        [ div [ class "box is-rounded has-text-left" ]
            [ div [ class "content" ]
                [ p []
                    [ text "Aplikacja jest prostym komunikatorem tekstowym wykonanym w ramach studiów na Politechnice Warszawskiej." ]
                , p []
                    [ text "Funkcjonalności:" ]
                , ul []
                    [ li []
                        [ text "Rejestracja użytkowników" ]
                    , li []
                        [ text "Logowanie użytkowników" ]
                    , li []
                        [ text "Dodawanie znajomych " ]
                    , li []
                        [ text "Tworzenie konwersacji " ]
                    , li []
                        [ text "Komunikacja w konwersacjach z jednym bądź wieloma innymi użytkownikami w czasie rzeczywistym" ]
                    ]
                , p []
                    [ text "Technologie:" ]
                , ul []
                    [ li [] [ text "Strona posiada certyfikat SSL" ]
                    , li [] [ text "Strona jest opatrzona stosownymi tagami które umożliwiają korzystanie z komunikatora przy pomocy oprogramowania czytającego." ]
                    , li []
                        [ text "Po stronie servera:     "
                        , ul []
                            [ li []
                                [ text "Java " ]
                            , li []
                                [ text "Spring Boot " ]
                            , li []
                                [ text "H2" ]
                            ]
                        ]
                    , li []
                        [ text "Po stronie klienta:    "
                        , ul []
                            [ li []
                                [ text "Elm " ]
                            , li []
                                [ text "Skrypty Javascript" ]
                            , li []
                                [ text "Stylowanie przy użyciu bilioteki Bulma" ]
                            ]
                        ]
                    ]
                , p []
                    [ text "Nawigacja:" ]
                , ol []
                    [ li []
                        [ text "Zmiana języka : Polski i Angielski" ]
                    , li []
                        [ text "Przejście do ekranu z informacjami o projekcie" ]
                    , li []
                        [ text "Przejscie do ekranu znajomych" ]
                    , li []
                        [ text "Przejscie do ekranu  konwersacji" ]
                    , li []
                        [ text "Logowanie/Wylogowanie" ]
                    ]
                , img [ class "image is-fullwidth", Html.Attributes.style "max-width" "none", src "navbar-info.png" ] []
                , p []
                    [ text "Możliwe operacje na ekranie znajomych:" ]
                , ol []
                    [ li []
                        [ text " Dodawanie znajomych" ]
                    , li []
                        [ text "Akceptacja/odmowa propozycji znajomości" ]
                    ]
                , img [ class "image is-fullwidth", Html.Attributes.style "max-width" "none", src "friends-info.png" ] []
                , p []
                    [ text "Możliwe operacje na ekranie konwersacji" ]
                , ol []
                    [ li []
                        [ text "Utworzenie konwersacji " ]
                    , li []
                        [ text "Wybranie aktywnej konwersacji" ]
                    , li []
                        [ text "Wysyłanie wiadomości w konwersacji. Wideo Youtube jest zagnieżdżane, wysyłając linka filmu, np: https://www.youtube.com/watch?v=KyPjE1Sn-Ts  " ]
                    ]
                , img [ class "image is-fullwidth", Html.Attributes.style "max-width" "none", src "conversation-info.png" ] []
                , p []
                    [ text "Utworzenie konwersacji:" ]
                , ol []
                    [ li []
                        [ text "Wybranie nazwy konwersacji " ]
                    , li []
                        [ text "Wybranie znajomych do dodania do konwersacji" ]
                    ]
                , img [ class "image is-fullwidth", Html.Attributes.style "max-width" "none", src "add-conversation-info.png" ] []
                ]
            ]
        ]