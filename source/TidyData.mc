using Toybox.System as Sys;

class TidyData {
  var data = [0];
  var writeIdx = 0;
  var readIdx = 0;

  var dSz = 0;
  var distTrue = 0.0;
  var timeTrue = 0;
  var lapDist = 0.0;
  var distTotal = 0;
  var timeTotal = 0;
  var cadTotal  = 0;
  var ready = false;

  function fm () {
      var fm = Sys.getSystemStats().freeMemory;
      return fm;
  }

  function initialize(lDist) {
    lapDist = lDist * 100.0;

    var max;
    var nrOf;
    var _fm = fm();

    if (_fm > 10000) {
      nrOf = lDist < 1000 ? lDist.toNumber() : 1000;
    } else {
      max = _fm / 5;
      // at most we can have half of the memory,
      // but must also leave a bunch for drawing
      max = max > 1500 ? max / 2 : max - 750;
      max = max < 2 ? 2 : max;
      nrOf = lDist < max ? lDist.toNumber() : max;
    }
    // steal as much as we can, give up when we have to
    while (nrOf >= 10) {
      data.addAll([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
      nrOf -= 10;
    }
    while (nrOf > 0) {
      data.add(0);
      nrOf--;
    }
    dSz = data.size();
  }

  function reset() {
    for(var a=0; a<dSz; a++){ data[a] = 0; }
    writeIdx = 0;
    readIdx = 0;
    distTrue = 0.0;
    timeTrue = 0;
    distTotal = 0;
    timeTotal = 0;
    cadTotal  = 0;
    ready = false;
  }

  function add(dist, time, cad) {
    var d, t, c, tmp, prevRead;

    d = ((dist - distTrue)*100).toNumber(); // we keep 100ths
    t = (time - timeTrue).toNumber()/10; // and 100ths of a sec
    c = cad == null ? 0 : cad;

    data[writeIdx] = ((d<<20)+(t<<9)+c).toNumber(); // force 32 bit

    // if our distance delta isn't lD/dSz we don't update the actuals
    // this means we actually end up with a heap of wasted space
    if (d >= lapDist/dSz) {
      distTotal += d;
      timeTotal += t;
      cadTotal += c*t;
      if ( distTotal >= lapDist ) { ready = true; }

      prevRead = readIdx;

      while(distTotal >= lapDist * (1.0 + 1.0/dSz)) {
        tmp = data[readIdx];
        d = (tmp >> 20) & 0xfff;
        t = (tmp >> 9) & 0x7ff;
        c = tmp & 0x1ff;
        readIdx = (readIdx + 1) % dSz;
        if ( readIdx == prevRead ) {
          reset();
          return;
        }
        distTotal -= d;
        timeTotal -= t;
        cadTotal -= c*t;
      }
      writeIdx = (writeIdx + 1) % dSz;
      distTrue = dist;
      timeTrue = time;
    }

  }
}