var ago = (function(){
  var MS =
    { seconds:                        1000
    , minutes:                   60 * 1000
    , hours:                60 * 60 * 1000
    , days:            24 * 60 * 60 * 1000
    , weeks:       7 * 24 * 60 * 60 * 1000
    , months: 30 * 7 * 24 * 60 * 60 * 1000
    , years:     365 * 24 * 60 * 60 * 1000 }

  return ago

  function ago ( origin ) {
    var delta = Date.now() - origin.getTime()
      , ago

    if ( ago = doDelta( 'years') )
      return ~~ago + 'y'
    else if ( ago = doDelta( 'months') )
      return ~~ago + 'mo'
    else if ( ago = doDelta( 'weeks') )
      return ~~ago + 'w'
    else if ( ago = doDelta( 'days') )
      return ~~ago + 'd'
    else if ( ago = doDelta( 'hours') )
      return ~~ago + 'h'
    else if ( ago = doDelta( 'minutes') )
      return ~~ago + 'm'
    else if ( ago = doDelta( 'seconds') )
      return ~~ago + 's'

    return 'now'

    function doDelta ( type ) {
      var result = delta / MS[type]
      return result >= 1 && result
    }
  }

})()
