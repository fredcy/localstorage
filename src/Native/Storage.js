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

    function set(key, value) {
        window.console.log("set", key, value);
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
        set: F2(set),
    };

}();
