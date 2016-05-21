// Code borrowed shamelessly from https://github.com/w0rm/elm-flatris

var _fredcy$storage$Native_LocalStorage = function()
{
    function storageAvailable(type) {
	try {
	    var storage = window[type],
		x = '__storage_test__';
	    storage.setItem(x, x);
	    storage.removeItem(x);
	    return true;
	}
	catch(e) {
	    return false;
	}
    }

    // shorthand for native APIs
    var unit = {ctor: '_Tuple0'};
    var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
    var succeed = _elm_lang$core$Native_Scheduler.succeed;
    var fail = _elm_lang$core$Native_Scheduler.fail;
    var Nothing = _elm_lang$core$Maybe$Nothing;
    var Just = _elm_lang$core$Maybe$Just;
    

    function set(key, value) {
        return nativeBinding(function(callback) {
            localStorage.setItem(key, value);
            return callback(succeed( unit ));
        });
    }


    function get (key) {
        return nativeBinding(function(callback) {
            var value = localStorage.getItem(key);
            return callback(succeed(
                (value === null) ? Nothing : Just(value)
            ));
        });
    }
    

    function remove (key) {
        return nativeBinding(function(callback) {
            localStorage.removeItem(key);
            return callback(succeed( unit ));
        });
    }
    

    var keys = nativeBinding(function(callback) {
        var _keys = [];
        for (var i = 0; i < localStorage.length; i++) {
            var key = localStorage.key(i);
            _keys.push(key);
        }
        return callback(succeed(
            _elm_lang$core$Native_List.fromArray( _keys )
        ));
    });


    var clear = nativeBinding(function(callback) {
        localStorage.clear();
        return callback(succeed( unit ));
    });


    var storageFail = nativeBinding(function(callback) {
            return callback(fail( {ctor: 'NoStorage'} ));
    });
    

    if (storageAvailable('localStorage')) {
        return {
            get: get,
            set: F2(set),
            remove: remove,
            clear: clear,
            keys: keys,
        }
    }
    else {
        return {
            get: storageFail,
            set: storageFail,
            remove: storageFail,
            clear: storageFail,
            keys: storageFail,
        }
    }

}();
