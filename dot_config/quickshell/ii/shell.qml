//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the shell smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1


import "./modules/common/"
import "./modules/overview/"

import QtQuick
import QtQuick.Window
import Quickshell
import "./services/"

ShellRoot {
    property bool enableOverview: true
    LazyLoader { active: enableOverview; component: Overview {} }
}

