#
# NoGroundDamage addon
#
# @author Benedikt Hallinger, 2021

var main = func( addon ) {
    var root = addon.basePath;
    var myAddonId  = addon.id;
    var mySettingsRootPath = "/addons/by-id/" ~ myAddonId;
    var minSpeed = 45;

    setlistener("sim/signals/fdm-initialized", func {
        print("Addon NoGroundDamage loading...");
        
        
        # in props
        var elapsedT = props.globals.getNode("/sim/time/elapsed-sec");
        var gsp_prop = props.globals.getNode("/velocities/groundspeed-kt");
        
        # out props
        var onground_prop = props.globals.getNode("/addons/by-id/org.hallinger.flightgear.NoGroundDamage/onground",1);
        var speed_prop    = props.globals.getNode("/addons/by-id/org.hallinger.flightgear.NoGroundDamage/speed-reached",1);
        
        # Calculate timed properties. They should filter short lived prop changes.
        var onGround_laststatechange = 0;
        var onGroundTimer = maketimer(1, func(){
            var wow = 0;
            for (var i=0; i < 3; i = i+1) {
                var wow_p = getprop("/gear/gear["~i~"]/wow");
                if (!isscalar(wow_p)) wow_p = 0;
                if (wow_p) wow = 1;
                #print("Addon NoGroundDamage onGroundTimer WOW check: "~i~"="~wow_p~"; wow="~wow);
            }
            #print("Addon NoGroundDamage onGroundTimer elapsedT="~elapsedT.getValue()~"; onGround_laststatechange="~onGround_laststatechange);
            if (elapsedT.getValue() >= onGround_laststatechange + 20) {
                if (wow) {
                    onground_prop.setBoolValue(1);
                    #print("Addon NoGroundDamage onGroundTimer WOW detected, setting onground_prop=1");
                    onGround_laststatechange = elapsedT.getValue();
                }
                
            }
            if (elapsedT.getValue() >= onGround_laststatechange + 3) {
                if (!wow) {
                    onground_prop.setBoolValue(0);
                    #print("Addon NoGroundDamage onGroundTimer WOW released, setting onground_prop=0");
                    onGround_laststatechange = elapsedT.getValue();
                }
            }
        });
        onGroundTimer.start();
        
        var speed_laststatechange = 0;
        var speedTimer = maketimer(1, func(){
            #print("Addon NoGroundDamage speedTimer elapsedT="~elapsedT.getValue()~"; speed_laststatechange="~speed_laststatechange);
            if (elapsedT.getValue() >= speed_laststatechange + 5) {
                if (gsp_prop.getValue() >= minSpeed) {
                    speed_prop.setBoolValue(1);
                    #print("Addon NoGroundDamage speedTimer speed bigger threshold, setting speed_prop=1");
                    speed_laststatechange = elapsedT.getValue();
                }
            }
            if (elapsedT.getValue() >= speed_laststatechange + 0.5) {
                if (gsp_prop.getValue() < minSpeed) {
                    speed_prop.setBoolValue(0);
                    #print("Addon NoGroundDamage speedTimer speed lower threshold, setting speed_prop=0");
                    speed_laststatechange = elapsedT.getValue();
                }
            }
        });
        speedTimer.start();
        
        
        
        # Logic to calculate final state
        var checkTimer = maketimer(1, func(){
            #print("Addon NoGroundDamage checkTimer: onground_prop="~onground_prop.getValue()~"; speed_prop="~speed_prop.getValue());
            if (onground_prop.getValue() and !speed_prop.getValue()) {
                setprop("/fdm/jsbsim/settings/damage", 0);
            } else {
                setprop("/fdm/jsbsim/settings/damage", 1);
            }
        });
        checkTimer.start();
        
    });
}
