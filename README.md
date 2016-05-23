# LocalStorage

Local storage for Elm.

This library offers access to the browser's localstorage, which is
limited to string keys and values. It uses Elm Tasks for storage IO.

It also provides a Subscription to localstorage events.

## Installing the beta version

Since this module is not available as a package you'll have to use it from
source.  See the example/elm-package.json file for the necessary
configuration. Even the `repository` name has to match for the native code to
build.

## Credits

This work is derived directly from the LocalStorage.elm module in elm-flatris.

+ https://github.com/w0rm/elm-flatris
+ https://github.com/xdissent/elm-localstorage
