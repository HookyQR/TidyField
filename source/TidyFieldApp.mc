using Toybox.Application as App;

class TidyFieldApp extends App.AppBase {
    var view;
    function initialize()     { AppBase.initialize(); }
    function getInitialView() { view = new TidyFieldView(); return [ view ];}
    function onSettingsChanged() { view.onSettingsChanged(); }
}