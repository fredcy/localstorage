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

    var unit = {ctor: '_Tuple0'};


    function get (key) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            var value = localStorage.getItem(key);
            return callback(_elm_lang$core$Native_Scheduler.succeed(
                (value === null) ? _elm_lang$core$Maybe$Nothing : _elm_lang$core$Maybe$Just(value)
            ));
        });
    }
    

    function remove (key) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            localStorage.removeItem(key);
            return callback(_elm_lang$core$Native_Scheduler.succeed( unit ));
        });
    }
    

    var keys = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var _keys = [];
        for (var i = 0; i < localStorage.length; i++) {
            var key = localStorage.key(i);
            _keys.push(key);
        }
        return callback(_elm_lang$core$Native_Scheduler.succeed(
            _elm_lang$core$Native_List.fromArray( _keys )
        ));
    });


    function set(key, value) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            localStorage.setItem(key, value);
            return callback(_elm_lang$core$Native_Scheduler.succeed( value ));
        });
    }


    var clear = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        localStorage.clear();
        return callback(_elm_lang$core$Native_Scheduler.succeed( unit ));
    });


    var storageFail = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            return callback(_elm_lang$core$Native_Scheduler.fail({ctor: 'NoStorage'}));
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
