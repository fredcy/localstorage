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


    var length = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)	{
	if (storageAvailable('localStorage')) {
	    callback(_elm_lang$core$Native_Scheduler.succeed({
		length: localStorage.length(),
	    }));
	}
	else {
	    // TODO: how to return a failure???
	    callback(_elm_lang$core$Native_Scheduler.succeed({
		length: 999,
	    }));
	}
    });

    return {
	length: length,
    };

}();
