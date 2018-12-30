using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.ActivityMonitor as Monitor;
using Toybox.SensorHistory as History;
using Toybox.Math as Math;
using Toybox.Activity as Actvity;
using Toybox.Application as Application;

class ChronosTerminalWatchfaceView extends Ui.WatchFace
{

	var message = false;
	var fr;
	var highContrast;
	
	function initialize()
	{
	
		WatchFace.initialize();
		var device = Ui.loadResource(Rez.Strings.device);
		fr = device.equals("fr630") ? true : false;
		highContrast = Application.getApp().getProperty("highContrast");
	}
	
	
	function onLayout(dc)
	{
		if(!highContrast){setLayout(Rez.Layouts.WatchFace(dc));}
		else{setLayout(Rez.Layouts.highContrastLayout(dc));}
	}
	
	function onShow()
	{
		
	}
	
	function getHighIterator() {
    // Check device for SensorHistory compatability
    if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getElevationHistory)) {
       // Set up the method with parameters
        var getMethod = new Lang.Method
            (
            Toybox.SensorHistory,
            :getElevationHistory
            );
        // Invoke the method with the given parameters
        return getMethod.invoke({});
    }
    return null;
	}
	
	function getHeartIterator() {
    // Check device for SensorHistory compatability
    if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getHeartRateHistory)) {
        // Set up the method with parameters
        var getMethod = new Lang.Method
            (
            Toybox.SensorHistory,
            :getHeartRateHistory
            );
        // Invoke the method with the given parameters
        return getMethod.invoke({});
    }
    return null;
	}
	
	
	function createView(name, text)
	{
		var view = View.findDrawableById(name);
		view.setText(text);
	}
	
	function createTimeString(clockTime)
	{
		return Lang.format("$1$:$2$",[clockTime.hour.format("%02d"),clockTime.min.format("%02d")]);
	}
	
	function createClockTime(clockTime,offset,minOffset,dst)
	{
		clockTime.hour -=clockTime.timeZoneOffset/3600;
		clockTime.min -=(clockTime.timeZoneOffset/60) %60;
		//if(offset < -2){Sys.println(clockTime.hour);}
		clockTime.hour += offset;
		if(clockTime.min + minOffset < 60){clockTime.min += minOffset;}
		else
		{
			clockTime.min += minOffset;
			clockTime.hour += 1;
		}
		//if(offset < -2){Sys.println(clockTime.hour);}
		if(dst)
		{
			clockTime.hour += 1;
		}
		//if(clockTime.hour < 0){clockTime.hour = 24 - clockTime.hour;}
		//if(offset < -2){Sys.println(clockTime.hour);}
		if(clockTime.hour < 0){clockTime.hour = 24 + clockTime.hour;}
		if(clockTime.hour < 0){clockTime.min = 60 + clockTime.min;}
		clockTime.hour = clockTime.hour % 24;
		clockTime.min = clockTime.min % 60;
		return clockTime;
	}
	
	function onUpdate(dc)
	{
		var todayTime = Time.today();
		var today = Gregorian.info(todayTime, Time.FORMAT_MEDIUM);
		
		var dstUsaOn = Gregorian.momentNative(today.year, 3, 12, 2, 0, 0);
		var dstUsaOff = Gregorian.momentNative(today.year, 11, 5, 2, 0, 0);
		
		var dstDeOn = Gregorian.momentNative(today.year, 3, 26, 2, 0, 0);
		var dstDeOff = Gregorian.momentNative(today.year, 10, 29, 3, 0, 0);
		
		var now = Time.now();
		var dstUSA = now.greaterThan(dstUsaOn) && now.lessThan(dstUsaOff);
		var dstDE = now.greaterThan(dstDeOn) && now.lessThan(dstDeOff);
		
		//Settings
		var app = Application.getApp();
		
		var timeZone1 = app.getProperty("timeZone1").toString();
		var timeZone2 = app.getProperty("timeZone2").toString();
		var timeZone3 = app.getProperty("timeZone3").toString();
		
		var timeZone1Offset = app.getProperty("timeZone1Offset").toNumber();
		var timeZone2Offset = app.getProperty("timeZone2Offset").toNumber();
		var timeZone3Offset = app.getProperty("timeZone3Offset").toNumber();
		
		
		var timeZone1MinOffset = app.getProperty("timeZone1MinOffset").toNumber();
		var timeZone2MinOffset = app.getProperty("timeZone2MinOffset").toNumber();
		var timeZone3MinOffset = app.getProperty("timeZone3MinOffset").toNumber();
		
		if(timeZone1Offset < 0){timeZone1MinOffset = -timeZone1MinOffset;}
		if(timeZone2Offset < 0){timeZone2MinOffset = -timeZone2MinOffset;}
		if(timeZone3Offset < 0){timeZone3MinOffset = -timeZone3MinOffset;}
		
		var timeZone1DST = app.getProperty("timeZone1DST");
		var timeZone2DST = app.getProperty("timeZone2DST");
		var timeZone3DST = app.getProperty("timeZone3DST");
		
		var dstZ1;
		var dstZ2;
		
		var male = app.getProperty("male");
		var active = app.getProperty("active");
		var age = app.getProperty("age").toDouble();
		var weight = app.getProperty("weight").toDouble();
		var height = app.getProperty("height").toDouble();
		
		//Mifflin-St.Jeor-Formula
		var bmr = 0;
		if(male)
		{
			bmr = 10*weight + 6.25*height - 5*age + 5;
		}
		else
		{
			bmr = 41.87*weight + 26.17*height - 20.93*age - 161;
		}
		
		
		//Sys.println(timeZone1 + " --> "+timeZone1Offset+" , DST: " + timeZone1DST);
		//Sys.println(timeZone1Offset==-5);
		
		if(timeZone1.equals("DET") && timeZone1Offset==-5 && timeZone1MinOffset==0){dstZ1=dstUSA;}
		else{dstZ1=timeZone1DST;}
		
		if(timeZone2.equals("FRA") && timeZone1Offset==1 && timeZone2MinOffset==0){dstZ2=dstDE;}
		else{dstZ2=timeZone2DST;}
		
		createView("Zone1",timeZone1);
		createView("Zone2",timeZone2);
		createView("Zone3",timeZone3);
		
		createView("TimeLabel",createTimeString(Sys.getClockTime()));
		createView("TimeLabelGermany",createTimeString(createClockTime(Sys.getClockTime(),timeZone2Offset,timeZone2MinOffset,dstZ2)));
		createView("TimeLabelAmerica",createTimeString(createClockTime(Sys.getClockTime(),timeZone1Offset,timeZone1MinOffset,dstZ1)));
		createView("TimeLabelSingapore",createTimeString(createClockTime(Sys.getClockTime(),timeZone3Offset,timeZone3MinOffset,timeZone3DST)));
		
		createView("Date",Lang.format("$3$ $1$. $2$",[today.day.format("%02d"),today.month,today.day_of_week.substring(0,2)]));
		
		var history = Monitor.getInfo();
		
		//Sys.print(history.calories);
		
		if(!fr){
		var high = getHighIterator().next().data;
		var heart = getHeartIterator().next().data;
		//var temp = getTempIterator().next().data;
		
		var viewHigh = View.findDrawableById("High");
		if(high!=null){viewHigh.setText(Math.round(high).toNumber().toString());}
		else{viewHigh.setText("0");}
				
		var viewHeart = View.findDrawableById("Heart");
		if(heart!=null){viewHeart.setText(heart.toString());}
		else{viewHeart.setText("0");}
		}
		
		//if(temp!=null){viewTemp.setText(Math.round(temp).toNumber().toString()+" C");}
		//else{viewTemp.setText("0 C");}
		var hour = history.calories.toDouble() <= bmr*(Sys.getClockTime().hour.toDouble()/24) ? 0 : (history.calories.toDouble() - bmr*(Sys.getClockTime().hour.toDouble()/24)).toNumber();
		//Sys.print(hour);
		createView("Steps",history.steps.toString());
		if(!active){createView("Burned",history.calories.toString());}
		else{createView("Burned",hour.toString());}
		createView("Distance",(history.distance.toFloat()/100000f).format("%02.1f"));
		
		createView("Battery",Math.round(Sys.getSystemStats().battery).toNumber().toString()+"%");
		
		var ds = Sys.getDeviceSettings();
		
		var iconString = (!highContrast) ? "icon" : "icon2";
		var icon = View.findDrawableById(iconString);
		if(ds has :phoneConnected && ds.phoneConnected == true)
		{
			if(!fr){icon.locX=113;}else{icon.locX=100;}
			icon.locY=0;
		}
		else
		{
			icon.locX=0;
			icon.locY=0;	
		}
		
		var white = Gfx.COLOR_WHITE;
		var black = Gfx.COLOR_BLACK;
		var red = Gfx.COLOR_RED;
		var gray = Gfx.COLOR_DK_GRAY;
		
		var fg;
		var bg;
		var highlight;
		var fg2;
		
		if(!highContrast)
		{
			fg = white;
			bg = black;
			highlight = red;
			fg2 = gray;
		}		
		else
		{
			fg = black;
			bg = white;
			highlight = red;
			fg2 = black;
		}
		
		dc.setColor(fg,bg);
		
		View.onUpdate(dc);
		
		if(ds.notificationCount>0)
		{
			dc.setColor(highlight,bg);
			if(!fr){
			dc.drawText(30,80,Gfx.FONT_XTINY,ds.notificationCount.toString(),Gfx.TEXT_JUSTIFY_CENTER);}
			else {
			dc.drawText(40,60,Gfx.FONT_XTINY,ds.notificationCount.toString(),Gfx.TEXT_JUSTIFY_CENTER);}
		}
		else
		{
			dc.setColor(fg2,bg);
			if(!fr){dc.drawText(30,80,Gfx.FONT_XTINY,"0",Gfx.TEXT_JUSTIFY_CENTER);}
			else{dc.drawText(40,60,Gfx.FONT_XTINY,"0",Gfx.TEXT_JUSTIFY_CENTER);}
		}
			dc.setColor(fg,bg);
		
		//dc.setColor(white,black);
		
		if(!fr)
		{
			dc.drawLine(0,110,240,110);
			dc.drawLine(0,160,240,160);
			dc.drawLine(0,185,240,185);
			dc.drawLine(0,213,240,213);
			dc.drawLine(120,160,120,213);
		}
		else
		{
			dc.drawLine(0,80,215,80);
			dc.drawLine(0,120,215,120);
			dc.drawLine(0,145,215,145);
			dc.drawLine(0,170,215,170);
			dc.drawLine(107,120,107,170);
		}
		
		
	}
}