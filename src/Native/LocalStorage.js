// Code borrowed shamelessly from https://github.com/w0rm/elm-flatris

var _fredcy$localstorage$Native_LocalStorage = function()
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

    function isStorageAvailable() {
        if (typeof window === "undefined"){
            return false;
        } else if (!storageAvailable('localStorage') || typeof window.localStorage === "undefined"){
            return false;
        }
        return true;
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
            try {
                localStorage.setItem(key, value);
                return callback(succeed( unit ));
            } catch (e) {
                return callback(fail( {'ctor': 'Overflow'} ));
            }
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

    function storageFail2(a, b) {
	return storageFail;
    }
    function storageFail1(a) {
        return storageFail;
    }


    if (isStorageAvailable()) {
        return {
            get: get,
            set: F2(set),
            remove: remove,
            clear: clear,
            keys: keys
        }
    }
    else {
        return {
            get: storageFail1,
            set: F2(storageFail2),
            remove: storageFail1,
            clear: storageFail,
            keys: storageFail
        }
    }

}();
