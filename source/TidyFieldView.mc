using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.UserProfile as Prof;

class TidyFieldView extends Ui.DataField {

    var measurements;
    var is24Hour = false;

    var cadDiv = 1;
    var cadStr = "lap!F";
    var unitsDiv = 1.0;
    var units = "km";

    var cad = 0;
    var spd = 0.0;
    var time = 0;
    var dst = 0.0;

    var avgCad = 0;
    var avgSpd = 0.0;

    var slideCad = 0;
    var slideSpd = 0.0;
    var slideTime = 0;

    var lapDist = 500.0;
    var hr = null;

    var dispStrings = [];
    var rolling;

    function initialize() {
        DataField.initialize();
        var sport = Prof.getCurrentSport();
        switch( sport ){
            case Prof.HR_ZONE_SPORT_BIKING:{
                lapDist = App.getApp().getProperty("cyclingLap");
                break;}
            case Prof.HR_ZONE_SPORT_SWIMMING:{
                lapDist = App.getApp().getProperty("swimmingLap");
                break;}
            case Prof.HR_ZONE_SPORT_RUNNING:{
                lapDist = App.getApp().getProperty("runningLap");
                break;}
            default:{
                lapDist = App.getApp().getProperty("genericLap");
                break;}
        }
        lapDist = lapDist * 1.0;
        rolling = new TidyData(lapDist);
    }

    function fm () {
        var fm = Sys.getSystemStats().freeMemory;
        return fm;
    }

    function dUnits() {
        var du = Sys.getDeviceSettings().distanceUnits;
        return du;
    }

    function tfHour() {
        var tf = Sys.getDeviceSettings().is24Hour;
        return tf;
    }
    function onSettingsChanged() {
        is24Hour = tfHour();

        var sport = Prof.getCurrentSport();
        cadStr = "lap!F";
        cadDiv = 1;
        if (sport == Prof.HR_ZONE_SPORT_BIKING){
            cadStr = "lap!C";
            cadDiv = 2;
        }
        if (sport == Prof.HR_ZONE_SPORT_SWIMMING){
            cadStr = "lap!A";
            cadDiv = 1;
        }
        units = "mi";
        unitsDiv = 1.60934;
        if (dUnits() == Sys.UNIT_METRIC) {
            units = "km";
            unitsDiv = 1.0;
        }

        rolling.reset(); // reset the data
    }
    function onLayout(dc) {
        onSettingsChanged();
        if ( dc.getWidth() == 240 ) {
            measurements = [
                27,  // start y
                46,  // segment height
                102, // two field middle
                64,  // quarterish
                120, // centerish
                198, // right
                21,  // drop to small
                14,  // drop to medium
                true
            ];
        } else {
            measurements = [
                27,   // start y
                43,  // segment height
                96,  // two field middle
                60,  // quarterish
                110, // centerish
                170,
                14,  // drop to small
                14,  // drop to medium
                true
            ];
        }
        if (dc.getWidth() > dc.getHeight()) {
            measurements[0] = 8;
            measurements[8] = false;
        }
        return true;
    }

    function compute(info) {
        hr = info.currentHeartRate;
        cad = info.currentCadence == null ? cad : info.currentCadence;
        dst = info.elapsedDistance == null ? dst : info.elapsedDistance;
        spd = info.currentSpeed == null ? spd: info.currentSpeed;
        // time = info.elapsedTime == null ? time : info.elapsedTime; // includes pause
        time = info.timerTime == null ? time : info.timerTime; // without pause
        avgCad = info.averageCadence == null ? avgCad : info.averageCadence;
        avgSpd = info.averageSpeed == null ? avgSpd: info.averageSpeed;

        cad /= cadDiv;
        avgCad /= cadDiv;
        spd *= 3.6/unitsDiv;
        avgSpd *= 3.6/unitsDiv;
        dst /= 1000.0*unitsDiv;

        if (
            info.elapsedTime == null ||
            info.startTime == null || // if we haven't started, we don't calc here
            info.elapsedDistance == null ) { return; }

        // rolling.add(info.elapsedDistance, info.elapsedTime, info.currentCadence);
        rolling.add(info.elapsedDistance, info.timerTime, info.currentCadence);

        if ( rolling.ready ) {
            slideCad = rolling.cadTotal / rolling.timeTotal / cadDiv;
            slideSpd = 3.6 * rolling.distTotal / rolling.timeTotal / unitsDiv;
            slideTime = (1000 * lapDist * rolling.timeTotal / rolling.distTotal).toNumber();
        } else {
            slideCad = avgCad;
            slideSpd = avgSpd;
            slideTime = time;
        }
    }

    function drawTxt(dc, y) {
        var fnt = Ui.loadResource(Rez.Fonts.txt);
        dc.drawText(measurements[3], y, fnt, "avg", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(measurements[4], y, fnt, cadStr, Gfx.TEXT_JUSTIFY_RIGHT);
        y += measurements[1];
        dc.drawText(measurements[3], y, fnt, "avg", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(measurements[4], y, fnt, "lap!S", Gfx.TEXT_JUSTIFY_RIGHT);
        y += measurements[1];
        dc.drawText(measurements[4], y-1, fnt, "total!T", Gfx.TEXT_JUSTIFY_RIGHT);
        y += measurements[1];
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        }
        dc.drawText(measurements[2], y, fnt, "H", Gfx.TEXT_JUSTIFY_RIGHT);
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        }
        dc.drawText(measurements[5]+2, y-1, fnt, "D", Gfx.TEXT_JUSTIFY_LEFT);
        y += dc.getFontHeight(fnt);
        dc.drawText(measurements[5]+3, y, fnt, units, Gfx.TEXT_JUSTIFY_LEFT);
    }
    function drawSmall(dc, y) {
        var fnt = Ui.loadResource(Rez.Fonts.small);
        var str = avgCad.format("%3i");
        dc.drawText(measurements[3], y, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
        str = slideCad.format("%3i");
        dc.drawText(measurements[4], y, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
        y += measurements[1];
        str = avgSpd.format("%3.1f");
        dc.drawText(measurements[3], y, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
        str = slideSpd.format("%3.1f");
        dc.drawText(measurements[4], y, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
    }
    function drawMedium(dc, y, os){
        var fnt = Ui.loadResource(Rez.Fonts.medium);
        var sec, min, hour;
        sec = time / 1000;
        min = sec / 60;
        hour = min / 60;
        sec -= min * 60;
        min -= hour * 60;

        var str = (hour>0? hour.format("%2i")+":":"")+min.format("%2i")+":"+sec.format("%02i");
        dc.drawText(measurements[4], y + os, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
        y += measurements[1];
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        }
        str = hr != null ? hr.toString() : ".!!.!!.!!";
        dc.drawText(measurements[2]-17, y, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        }
        str = dst.format("%3.2f");
        dc.drawText(measurements[5], y, fnt, str, Gfx.TEXT_JUSTIFY_RIGHT);
        y += dc.getFontHeight(fnt) + 4;

        if (measurements[8]){
            var t = Sys.getClockTime();
            if (is24Hour) {
                str = t.hour.format("%02i")+t.min.format("%02i");
            } else {
                str = hourFmt(t.hour).format("%2i")+":"+t.min.format("%02i");
            }
            dc.drawText(measurements[4], y, fnt, str, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
    function drawLarge(dc, y) {
        var fnt = Ui.loadResource(Rez.Fonts.large);
        var str;
        str = cad.format("%3i");
        dc.drawText(measurements[4]+4, y, fnt, str, Gfx.TEXT_JUSTIFY_LEFT);
        y += measurements[1];
        str = spd.format("%5.2f");
        dc.drawText(measurements[4]+4, y, fnt, str, Gfx.TEXT_JUSTIFY_LEFT);
        y += measurements[1];
        var sec, min, hour;
        sec = slideTime / 1000;
        min = sec / 60;
        hour = min / 60;
        sec -= min * 60;
        min -= hour * 60;
        if ( !rolling.ready ){
            if (getBackgroundColor() == Gfx.COLOR_BLACK) {
                dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            }
        }
        str = min.format("%2i")+":"+sec.format("%02i");
        dc.drawText(measurements[4]+4, y, fnt, str, Gfx.TEXT_JUSTIFY_LEFT);
    }
    function onUpdate(dc) {
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
            dc.clear();
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
            dc.clear();
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        }
        drawTxt(dc, measurements[0]);
        drawSmall(dc, measurements[0]+measurements[6]);
        drawMedium(dc, measurements[0]+measurements[1] * 2, measurements[7]);
        drawLarge(dc, measurements[0]);
    }

  function hourFmt( h ) {
    if( h > 12 ){ h -= 12; }
    if ( h == 0){ h = 12; }
    return h;
  }
}
