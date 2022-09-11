// -*- mode:java; tab-width:2; c-basic-offset:2; intent-tabs-mode:nil; -*- ex: set tabstop=2 expandtab:

// ConnectIQ Raw Logger (RawLogger)
// Copyright (C) 2018-2019 Cedric Dufour <http://cedric.dufour.name>
//
// ConnectIQ Raw Logger (RawLogger) is free software:
// you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, Version 3.
//
// ConnectIQ Raw Logger (RawLogger) is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// See the GNU General Public License for more details.
//
// SPDX-License-Identifier: GPL-3.0
// License-Filename: LICENSE/GPL-3.0.txt

import Toybox.Lang;
using Toybox.Application as App;
using Toybox.ActivityRecording;
using Toybox.Attention;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi as Ui;

//
// GLOBALS
//

// Current view index and labels
var RL_iViewIndex as Number = 0;
var RL_sViewLabel1 as String?;
var RL_sViewLabel2 as String?;


//
// CLASS
//

class RL_View extends Ui.View {

  //
  // CONSTANTS
  //

  private const NOVALUE_BLANK = "";
  private const NOVALUE_LEN3 = "---";


  //
  // VARIABLES
  //

  // Display mode (internal)
  private var bShow as Boolean = false;

  // Screen center coordinates
  private var iWidthX as Number = 0;
  private var iHeightY as Number = 0;
  private var iCenterX as Number = 0;
  private var iCenterY as Number = 0;
  private var iStatusY as Number = 0;
  private var iLabel1Y as Number = 0;
  private var iLabel2Y as Number = 0;
  private var iValue1Y as Number = 0;
  private var iValue2Y as Number = 0;
  private var iValue3Y as Number = 0;


  //
  // FUNCTIONS: Ui.View (override/implement)
  //

  function initialize() {
    View.initialize();

    // Display mode
    // ... internal
    self.bShow = false;
  }

  function onLayout(_oDC) {
    //Sys.println("DEBUG: RL_View.onLayout()");

    // Screen center coordinates
    self.iWidthX = _oDC.getWidth();
    self.iHeightY = _oDC.getHeight();
    self.iCenterX = (self.iWidthX/2).toNumber();
    self.iCenterY = (self.iHeightY/2).toNumber();
    self.iStatusY = (self.iHeightY/8).toNumber();
    self.iLabel1Y = (self.iHeightY/5+self.iHeightY/8).toNumber();
    self.iLabel2Y = (self.iHeightY/5+self.iHeightY/8*2).toNumber();
    self.iValue1Y = (self.iHeightY/5+self.iHeightY/8*3).toNumber();
    self.iValue2Y = (self.iHeightY/5+self.iHeightY/8*4).toNumber();
    self.iValue3Y = (self.iHeightY/5+self.iHeightY/8*5).toNumber();
  }

  function onShow() {
    //Sys.println("DEBUG: RL_View.onShow()");
    self.bShow = true;
    $.RL_oCurrentView = self;


    // Turn on recording // TODO: do I need to turn it off?!
    if($.RL_oActivitySession == null) {
      (App.getApp() as RL_App).initActivity();
      ($.RL_oActivitySession as ActivityRecording.Session).start();
      if(Attention has :playTone) {
        Attention.playTone(Attention.TONE_START);
      }
    }

  }

  function onUpdate(_oDC) {
    //Sys.println("DEBUG: RL_View.onUpdate()");
    self.drawValues(_oDC);
  }

  function onHide() {
    //Sys.println("DEBUG: RL_View.onHide()");
    $.RL_oCurrentView = null;
    self.bShow = false;
  }


  //
  // FUNCTIONS: self
  //

  function updateUi() as Void {
    //Sys.println("DEBUG: RL_View.updateUi()");

    // Request UI update
    if(self.bShow) {
      Ui.requestUpdate();
    }
  }

  function drawValues(_oDC as Gfx.Dc) as Void {
    //Sys.println("DEBUG: RL_View.drawValues()");
    _oDC.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
    _oDC.clear();
    var sValue;

    if($.RL_oActivitySession != null) {  // ... activity status
      _oDC.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
      _oDC.drawText(self.iCenterX, self.iStatusY, Gfx.FONT_SMALL, "REC", Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    }

    if($.RL_iViewIndex == 0) {  // ... time
      // ... label
      _oDC.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
      if($.RL_sViewLabel2 == null) {
        $.RL_sViewLabel2 = Lang.format("$1$ [$2$]", [Ui.loadResource(Rez.Strings.labelTime), Ui.loadResource(Rez.Strings.unitTime)]);
      }
      _oDC.drawText(self.iCenterX, self.iLabel1Y, Gfx.FONT_SMALL, self.NOVALUE_BLANK, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
      _oDC.drawText(self.iCenterX, self.iLabel2Y, Gfx.FONT_SMALL, $.RL_sViewLabel2 as String, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
      // ... value(s)
      _oDC.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
      var oTimeInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
      sValue = Lang.format("$1$:$2$", [oTimeInfo.hour.format("%02d"), oTimeInfo.min.format("%02d")]);
      _oDC.drawText(self.iCenterX, self.iValue1Y, Gfx.FONT_SMALL, sValue, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    }

  }

}

class RL_ViewDelegate extends Ui.BehaviorDelegate {

  //
  // FUNCTIONS: Ui.BehaviorDelegate (override/implement)
  //

  function initialize() {
    BehaviorDelegate.initialize();
  }

  // Opens menu by holding bottom button (on Vivoactive 4)
  function onMenu() {
    //Sys.println("DEBUG: RL_ViewDelegate.onMenu()");
    // if($.RL_oActivitySession == null) {
      Ui.pushView(new Rez.Menus.menuSettings(), new MenuDelegateSettings(), Ui.SLIDE_IMMEDIATE);
    // }
    // else {
    //   if(Attention has :playTone) {
    //     Attention.playTone(Attention.TONE_ERROR);
    //   }
    // }
    return true;
  }

  function onBack(){
    // Turn off recording
    if($.RL_oActivitySession != null) {
      ($.RL_oActivitySession as ActivityRecording.Session).stop();
      ($.RL_oActivitySession as ActivityRecording.Session).save();
      (App.getApp() as RL_App).resetActivity();
      if(Attention has :playTone) {
        Attention.playTone(Attention.TONE_STOP);
      }
    }
    return true;
  }


}
