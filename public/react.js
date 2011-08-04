"use strict";

exports.constant  = _constant;
exports.distinct  = _distinct;
exports.drop      = _drop;
exports.dropFirst = partial(_drop, 1);
exports.filter    = _filter;
exports.map       = _map;
exports.merge     = _merge;
exports.switch    = _switch;
exports.take      = _take;
exports.takeFirst = partial(_take, 1);
exports.takeUntil = _takeUntil;
exports.zip       = _zip;

exports.fromDOMEvent    = fromDOMEvent;
exports.fromHTTPRequest = fromHTTPRequest;

/**
 * @return {number}
 */
function now() {
    return Date.now();
}

/**
 * @param {function(...):*} f
 * @param {number} t
 * @return {function(...):*}
 */
function _throttle(f, t) {
    var toID   = null;
    var prevTs = null;
    return function(/*args...*/) {
        var args = arguments;
        var ts = now();
        var elapsed = ts - (prevTs || 0);
        if (toID) {
            clearTimeout(toID);
            toID = null;
        }
        if (elapsed >= t) {
            prevTs = ts;
            f.apply(f, args);
        } else {
            //console.log("Call in", t - elapsed, "ms");
            toID = setTimeout(function() {
                prevTs = ts;
                f.apply(f, args);
            }, t - elapsed);
        }
    }
}

/**
 * @param {function(...):*} f
 * @param {number} t
 * @return {function(...):*}
 */
function _delay(f, t) {
    return function(/*args...*/) {
        var args = arguments;
        setTimeout(function() {
            return f.apply(f, args);
        }, t);
    }
}

/**
 * EventStream
 * @constructor
 */
function EventStream() {
    this.subscribeers = [];
}

/**
 * @param {function(*):*} f
 * @return {EventStream}
 */
EventStream.prototype.subscribe = function(f) {
    this.subscribeers.push(f);
    return this;
}

/**
 * @param {*} value
 * @return {Array}
 */
EventStream.prototype.publish = function(value) {
    return map(partial(flip(force), value),
        this.subscribeers);
}

/**
 * @param {EventStream} esA
 * @param {*} v
 * @return {EventStream}
 */
function _constant(esA, v) {
    var esB = new EventStream();
    esA.subscribe(function(_) {
        return esB.publish(v);
    });
    return esB;
}


/**
 * @param {function(*):*} f
 * @param {EventStream} esA
 * @return {EventStream}
 */
function _map(f, esA) {
    var esB = new EventStream();
    esA.subscribe(function(v) {
        esB.publish(f(v));
    });
    return esB;
}

/**
 * @param {function(*):*} p
 * @param {EventStream} esA
 * @return {EventStream}
 */
function _filter(p, esA) {
    var esB = new EventStream();
    esA.subscribe(function(v) {
        if (true === p(v)) {
            esB.publish(f(v));
        }
    });
    return esB;
}

/**
 * @param {number} n
 * @param {EventStream} esA
 * @return {EventStream}
 */
function _drop(n, esA) {
    var dropped = 0;
    var esB = new EventStream();
    esA.subscribe(function(v) {
        if (n > dropped) {
            ++dropped;
            return;
        }
        esB.publish(v);
    });
    return esB;
}

/**
 * @param {number} n
 * @param {EventStream} esA
 * @return {EventStream}
 */
function _take(n, esA) {
    var esB = new EventStream();
    var taken = 0;
    esA.subscribe(function(v) {
        if (taken < n) {
            ++taken;
            esB.publish(v);
        }
    });
    return esB;
}

/**
 * @param {EventStream} esA Stop taking when this produces a value
 * @param {EventStream} esB Take from this
 * @return {EventStream}
 */
function _takeUntil(esA, esB) {
    var esC = new EventStream();
    var until = false;
    esB.subscribe(function(v) {
        if (false === until) {
            esC.publish(v);
        }
    });
    esA.subscribe(function(_) {
        until = true;
    });
    return esC;
}

/**
 * @param {EventStream} esA
 * @param {EventStream} esB
 * @return {EventStream}
 */
function _zip(esA, esB) {
    var esC = new EventStream();
    var esAB = _merge(esA, esB);
    var received = 0;
    var prevVal;
    var subscribeer = function(v) {
        if (2 === ++received) {
            received = 0;
            esC.publish([prevVal, v]);
        } else {
            prevVal = v;
        }
    };
    esAB.subscribe(subscribeer);
    return esC;
}


/**
 * @param {EventStream} esA
 * @param {EventStream} esB
 * @return {EventStream}
 */
function _merge(esA, esB) {
    var esC = new EventStream();
    var subscribeer = function(v) {
        esC.publish(v);
    }
    esA.subscribe(subscribeer);
    esB.subscribe(subscribeer);
    return esC;
}

/**
 * An EventStream that publishes only when the value has changed from the previous one
 * @param {EventStream} esA
 * @return {EventStream}
 */
function _distinct(esA) {
    var esB = new EventStream();
    var lastVal;
    esA.subscribe(function(v) {
        if (v !== lastVal) {
            esB.publish(v);
        }
        lastVal = v;
    });
    return esB;
}

/**
 * Switch from one EventStream to another
 * @param {EventStream} esA
 * @param {function(EventStream):EventStream} f
 * @return {EventStream}
 */
function _switch(esA, f) {
    var esB = new EventStream();
    esA.subscribe(function(x) {
        f(x).subscribe(function(y) {
            esB.publish(y);
        });
    });
    return esB;
}

/**
 * Transform a DOM event into an EventStream
 * @param {*} target
 * @param {string} eventName
 * @return {EventStream}
 */
function fromDOMEvent(target, eventName) {
    var es = new EventStream();
    var eventListener = function(event) {
        es.publish(event);
    }
    target.addEventListener(eventName, eventListener, false);
    return es;
}

function fromHTTPRequest(url, method) {
    // TODO: implement
}
