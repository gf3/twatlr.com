"use strict";

/**
 * @param {*} x
 * @return {*}
 */
function id(x) {
    return x;
}

/**
 * @param {*} x
 * @param {*} _
 * @return {*}
 */
function constant(x, _) {
    return x;
}

/**
 * Map a function over an Array (or Array-like object)
 * @param {function(*): *} f
 * @param {*} xs
 * @return {Array}
 */
function map(f, xs) {
    var length = xs.length;
    var ys = [];
    var i = 0;
    while (i < length) {
        ys[i] = f(xs[i++]);
    }
    return ys;
}

/**
 * Filter an Array (or Array-like object)
 * @param {function(*):boolean} p
 * @param {*} xs
 * @return {Array}
 */
function filter(p, xs) {
    var length = xs.length;
    var ys = [];
    var i = 0;
    var j = 0;
    while (j < length) {
        if (true === p(xs[j])) {
            ys[i++] = xs[j];
        }
        ++j;
    }
    return ys;
}

/**
 * Fold an array from the left
 * @param {function(*, *):*} f Combining function
 * @param {*} z Initial value
 * @param {*} xs
 * @return {*}
 */
function foldl(f, z, xs) {
    var length = xs.length;
    var i = 0;
    while (i < length) {
        z = f(z, xs[i++]);
    }
    return z;
}

/**
 * Fold an array from the right
 * @param {function(*, *):*} f Combining function
 * @param {*} z Initial value
 * @param {*} xs An Array-like object
 * @return {*}
 */
function foldr(f, z, xs) {
    var i = xs.length;
    while (i--) {
        z = f(xs[i], z);
    }
    return z;
}

/**
 * @param {function(*):*} f
 * @param {*} x
 * @return {*}
 */
function force(f, x) {
    return f(x);
}

/**
 * Flip the arguments of a binary function
 * @param {function(*, *)} f
 * @return {function(*, *)}
 */
function flip(f) {
    return function(x, y) {
        return f(y, x);
    };
}

/**
 * Function composition
 * param {...function(...):*} fs
 * @return {function(*):*}
 */
function compose() {
    var fs = arguments;
    return function(x) {
        return foldr(force, x, fs);
    };
}

/**
 * Partially apply a function
 * $param {function(...):*} f
 * $param {...} args
 * @return {function(...):*}
 */
function partial() {
    var args = toArray(arguments);
    var f = args.shift();
    return function() {
        return f.apply(null,
            args.concat(toArray(arguments)));
    };
}

function toArray(xs) {
    return map(id, xs);
}

function append(xs, ys) {
    return xs.concat(ys);
}

// @function
var concat = partial(foldl, append, []);
