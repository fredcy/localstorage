// Code borrowed shamelessly from https://github.com/w0rm/elm-flatris


var _fredcy$storage$Native_Storage = function()
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


    function get (key) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            var value = localStorage.getItem(key);
            return callback(_elm_lang$core$Native_Scheduler.succeed(
                (value === null) ? _elm_lang$core$Maybe$Nothing : _elm_lang$core$Maybe$Just(value)
            ));
        });
    }
    

    var keys = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var length = localStorage.length;
        var _keys = [];
        for (var i = 0; i < length; i++) {
            var key = localStorage.key(i);
            _keys.push(key);
        }
        window.console.log("keys", _keys);
        return callback(_elm_lang$core$Native_Scheduler.succeed(
            _elm_lang$core$Native_List.fromArray(_keys)
        ));
    });


    function set(key, value) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            localStorage.setItem(key, value);
            return callback(_elm_lang$core$Native_Scheduler.succeed(value));
        });
    }


    var length = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)	{
	if (storageAvailable('localStorage')) {
            var length = localStorage.length;
	    return callback(_elm_lang$core$Native_Scheduler.succeed(length));
	}
	else {
	    return callback(_elm_lang$core$Native_Scheduler.fail({ctor: 'NoStorage'}));
	}
    });

    return {
	length: length,
        get: get,
        set: F2(set),
        keys: keys,
    };

}();
