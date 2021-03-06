/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QgsQuick 0.1 as QgsQuick
import lc 1.0
import "."  // import InputStyle singleton

Item {

  property int activeProjectIndex: -1
  property string activeProjectPath: __projectsModel.data(__projectsModel.index(activeProjectIndex), ProjectModel.Path)
  property var busyIndicator

  property real rowHeight: InputStyle.rowHeightHeader * 1.2
  property real iconSize: rowHeight/3
  property bool showMergin: false
  property real panelMargin: InputStyle.panelMargin

  function openPanel() {
    homeBtn.activated()
    projectsPanel.visible = true
  }

  function getStatusIcon(status, pending) {
    if (pending) return "stop.svg"

    if (status === "noVersion") return "download.svg"
    else if (status === "outOfDate") return "sync.svg"
    else if (status === "upToDate") return "check.svg"
    else if (status === "modified") return "sync.svg"

    return "more_menu.svg"
  }

  function refreshProjectList() {
    if (toolbar.highlighted === exploreBtn.text) {
      exploreBtn.activated()
    } else if (toolbar.highlighted === sharedProjectsBtn.text) {
      sharedProjectsBtn.activated()
    } else if (toolbar.highlighted === myProjectsBtn.text) {
      myProjectsBtn.activated()
    } else homeBtn.activated()
  }

  Component.onCompleted: {
    // load model just after all components are prepared
    // otherwise GridView's delegate item is initialized invalidately
    grid.model = __projectsModel
    merginProjectsList.model = __merginProjectsModel
  }

  Connections {
    target: __projectsModel
    onModelReset: {
       var index = __projectsModel.rowAccordingPath(activeProjectPath)
       if (index !== activeProjectIndex) {
        activeProjectIndex = index
       }
    }
  }

  Connections {
    target: __merginApi
    onListProjectsFinished: {
      busyIndicator.running = false
    }
    onListProjectsFailed: {
      reloadList.visible = true
    }
    onApiVersionStatusChanged: {
      busyIndicator.running = false
      if (__merginApi.apiVersionStatus === MerginApiStatus.OK && authPanel.visible) {
        if (__merginApi.userAuth.hasAuthData()) {
          authPanel.visible = false
          refreshProjectList()
        }
      } else if (toolbar.highlighted !== homeBtn.text) {
        authPanel.state = "login"
        authPanel.visible = true
      }
    }
    onAuthRequested: {
      busyIndicator.running = false
      authPanel.state = "login"
      authPanel.visible = true
    }
    onAuthChanged: {
      authPanel.pending = false
      if (__merginApi.userAuth.hasAuthData()) {
        authPanel.close()
        refreshProjectList()
      } else {
        homeBtn.activated()
      }
      projectsPanel.forceActiveFocus()
    }
    onAuthFailed: {
      authPanel.pending = false
      projectsPanel.forceActiveFocus()
    }
    onRegistrationFailed: authPanel.pending = false
    onRegistrationSucceeded: {
      authPanel.pending = false
      authPanel.state = "login"
    }
  }

  id: projectsPanel
  visible: false
  focus: true

  Keys.onReleased: {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      if ( authPanel.visible ) // back to project view
      {
        authPanel.visible = false;
        projectsPanel.forceActiveFocus();
        homeBtn.activated();
        event.accepted = true;
      }
      else if ( accountPanel.visible ) // back to project view
      {
        accountPanel.visible = false;
        event.accepted = true;
      }
      else if ( statusPanel.visible ) // back to project view
      {
        event.accepted = true;
        statusPanel.close();
      }
      else if ( projectsPanel.visible && !activeProjectPath ) // Closes app - no active project
      {
        return;
      }
      else if ( projectsPanel.visible ) // back to map
      {
        event.accepted = true;
        projectsPanel.visible = false;
      }
    }
  }

  Keys.forwardTo: authPanel.visible ? authPanel : []

  // background
  Rectangle {
    width: parent.width
    height: parent.height
    color: InputStyle.clrPanelMain
  }

  BusyIndicator {
    id: busyIndicator
    width: parent.width/8
    height: width
    running: false
    visible: running
    anchors.centerIn: parent
    z: authPanel.z + 1
  }

  PanelHeader {
    id: header
    height: InputStyle.rowHeightHeader
    width: parent.width
    color: InputStyle.clrPanelMain
    rowHeight: InputStyle.rowHeightHeader
    titleText: qsTr("Projects")

    onBack: {
      if (authPanel.visible) {
        authPanel.visible = false
        homeBtn.activated()
      } else {
        projectsPanel.visible = false
      }
    }
    withBackButton: projectsPanel.activeProjectPath || authPanel.visible

    Item {
      id: avatar
      width: InputStyle.rowHeightHeader * 0.8
      height: InputStyle.rowHeightHeader
      anchors.right: parent.right
      anchors.rightMargin: projectsPanel.panelMargin

      Rectangle {
        id: avatarImage
        anchors.centerIn: parent
        width: avatar.width
        height: avatar.width
        color: InputStyle.fontColor
        radius: width*0.5
        antialiasing: true

        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (__merginApi.userAuth.hasAuthData() && __merginApi.apiVersionStatus === MerginApiStatus.OK) {
              __merginApi.getUserInfo()
              accountPanel.visible = true
              reloadList.visible = false
            }
            else
              myProjectsBtn.activated() // open auth form
          }
        }

        Image {
          id: userIcon
          anchors.centerIn: avatarImage
          source: 'account.svg'
          height: avatarImage.height * 0.8
          width: height
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
        }

        ColorOverlay {
          anchors.fill: userIcon
          source: userIcon
          color: "#FFFFFF"
        }
      }
    }
  }

  SearchBar {
    id: searchBar
    y: header.height

    onSearchTextChanged: {
      if (toolbar.highlighted === homeBtn.text) {
        __projectsModel.searchExpression = text
      } else if (toolbar.highlighted === exploreBtn.text) {
        // Filtered by request
        exploreBtn.activated()
      } else if (toolbar.highlighted === sharedProjectsBtn.text) {
        __merginProjectsModel.searchExpression = text
      } else if (toolbar.highlighted === myProjectsBtn.text) {
        __merginProjectsModel.searchExpression = text
      }
    }
  }

  // Content
  ColumnLayout {
    id: contentLayout
    height: projectsPanel.height-header.height-searchBar.height-toolbar.height
    width: parent.width
    y: header.height + searchBar.height
    spacing: 0

    // Info label
    Item {
      id: infoLabel
      width: parent.width
      height: toolbar.highlighted === exploreBtn.text ? projectsPanel.rowHeight * 2 : 0
      visible: height

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        color: InputStyle.panelBackgroundDarker
        font.pixelSize: InputStyle.fontPixelSizeNormal
        text: qsTr("Explore public projects.")
        visible: parent.height
      }

      // To not propagate click on canvas on background
      MouseArea {
        anchors.fill: parent
      }

      Item {
        id: infoLabelHideBtn
        height: projectsPanel.iconSize
        width: height
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: projectsPanel.panelMargin
        anchors.topMargin: projectsPanel.panelMargin

        MouseArea {
          anchors.fill: parent
          onClicked: infoLabel.visible = false
        }

        Image {
          id: infoLabelHide
          anchors.centerIn: infoLabelHideBtn
          source: 'no.svg'
          height: infoLabelHideBtn.height
          width: height
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
        }

        ColorOverlay {
          anchors.fill: infoLabelHide
          source: infoLabelHide
          color: InputStyle.panelBackgroundDark
        }
      }

      Rectangle {
          id: borderLine
          color: InputStyle.panelBackground2
          width: parent.width
          height: 1 * QgsQuick.Utils.dp
          anchors.bottom: parent.bottom
      }
    }

    ListView {
      id: grid
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentWidth: grid.width
      clip: true
      visible: !showMergin

      property int cellWidth: width
      property int cellHeight: projectsPanel.rowHeight
      property int borderWidth: 1

      delegate: delegateItem

      Text {
        anchors.fill: parent
        textFormat: Text.RichText
        text: "<style>a:link { color: " + InputStyle.fontColor + "; }</style>" +
              qsTr("No downloaded projects found.%1Learn %2how to create projects%3 and %4download them%3 onto your device.")
              .arg("<br/>")
              .arg("<a href='"+ __inputHelp.howToCreateNewProjectLink +"'>")
              .arg("</a>")
              .arg("<a href='"+ __inputHelp.howToDownloadProjectLink +"'>")

        onLinkActivated: Qt.openUrlExternally(link)
        visible: grid.count === 0
        color: InputStyle.fontColor
        font.pixelSize: InputStyle.fontPixelSizeNormal
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        padding: InputStyle.panelMargin/2
      }
    }

    ListView {
      id: merginProjectsList
      visible: showMergin && !busyIndicator.running
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentWidth: grid.width
      clip: true

      property int cellWidth: width
      property int cellHeight: projectsPanel.rowHeight
      property int borderWidth: 1

      Label {
        anchors.fill: parent
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        visible: !merginProjectsList.contentHeight
        text: reloadList.visible ? qsTr("Unable to get the list of projects.") : qsTr("No projects found!")
        color: InputStyle.fontColor
        font.pixelSize: InputStyle.fontPixelSizeNormal
        font.bold: true
      }

      delegate: delegateItemMergin
    }
  }

  Component {
    id: delegateItem
    ProjectDelegateItem {
      id: delegateItemContent
      cellWidth: projectsPanel.width
      cellHeight: projectsPanel.rowHeight
      iconSize: projectsPanel.iconSize
      width: cellWidth
      height: passesFilter ? cellHeight : 0
      visible: height ? true : false
      statusIconSource:"more_menu.svg"
      itemMargin: projectsPanel.panelMargin
      projectFullName: (projectNamespace && projectName) ? (projectNamespace + "/" + projectName) : folderName
      disabled: !isValid // invalid project
      highlight: {
        if (disabled) return true
        return path === projectsPanel.activeProjectPath ? true : false
      }

      Menu {
        property real menuItemHeight: projectsPanel.rowHeight * 0.8
        id: contextMenu
        height: (projectNamespace && projectName) ? menuItemHeight * 2 : menuItemHeight
        width:Math.min( parent.width, 300 * QgsQuick.Utils.dp )
        leftMargin: Math.max(parent.width - width, 0)

        //! sets y-offset either above or below related item according relative position to end of the list
        onAboutToShow: {
          var itemRelativeY = parent.y - grid.contentY
          if (itemRelativeY + contextMenu.height >= grid.height)
            contextMenu.y = -contextMenu.height
          else
            contextMenu.y = parent.height
        }

        MenuItem {
          height:  (projectNamespace && projectName) ? contextMenu.menuItemHeight : 0
          visible: (projectNamespace && projectName)
          ExtendedMenuItem {
              height: parent.height
              rowHeight: parent.height
              width: parent.width
              contentText: qsTr("Status")
              imageSource: InputStyle.infoIcon
              overlayImage: true
          }
          onClicked: statusPanel.open(delegateItemContent.projectFullName)
        }
        MenuItem {
          height: contextMenu.menuItemHeight
          ExtendedMenuItem {
              height: parent.height
              rowHeight: parent.height
              width: parent.width
              contentText: qsTr("Remove from device")
              imageSource: InputStyle.removeIcon
              overlayImage: true
          }
          onClicked: {
            deleteDialog.relatedProjectIndex = index
            deleteDialog.open()
          }
        }
      }

      onItemClicked: {
        if (showMergin) return

        projectsPanel.activeProjectIndex = index
        projectsPanel.visible = false
      }

      onMenuClicked:contextMenu.open()
    }
  }

  Component {
    id: delegateItemMergin
    ProjectDelegateItem {
      cellWidth: projectsPanel.width
      cellHeight: projectsPanel.rowHeight
      width: cellWidth
      height: passesFilter ? cellHeight : 0
      visible: height ? true : false
      pending: pendingProject
      statusIconSource: getStatusIcon(status, pendingProject)
      iconSize: projectsPanel.iconSize
      projectFullName: __merginApi.getFullProjectName(projectNamespace, projectName)
      progressValue: syncProgress

      onMenuClicked: {
        if (status === "upToDate") return

        if (pendingProject) {
          if (status === "modified") {
            __merginApi.uploadCancel(projectFullName)
          }
          if (status === "noVersion" || status === "outOfDate") {
            __merginApi.updateCancel(projectFullName)
          }
          return
        }

        if (status === "noVersion" || status === "outOfDate") {
          var withoutAuth = !__merginApi.userAuth.hasAuthData() && toolbar.highlighted === exploreBtn.text
          __merginApi.updateProject(projectNamespace, projectName, withoutAuth)
        } else if (status === "modified") {
          __merginApi.uploadProject(projectNamespace, projectName)
        }
      }

    }
  }


  // Toolbar
  Rectangle {
    property int itemSize: toolbar.height * 0.8
    property string highlighted: homeBtn.text

    id: toolbar
    height: InputStyle.rowHeightHeader
    width: parent.width
    anchors.bottom: parent.bottom
    color: InputStyle.clrPanelBackground

    MouseArea {
      anchors.fill: parent
      onClicked: {} // dont do anything, just do not let click event propagate
    }

    onHighlightedChanged: {
      searchBar.deactivate()
      if (toolbar.highlighted === homeBtn.text) {
        __projectsModel.searchExpression = ""
      } else {
        __merginApi.pingMergin()
      }
    }

    Row {
      height: toolbar.height
      width: parent.width
      anchors.bottom: parent.bottom

      Item {
        width: parent.width/parent.children.length
        height: parent.height

        MainPanelButton {

          id: homeBtn
          width: toolbar.itemSize
          text: qsTr("Home")
          imageSource: "home.svg"
          faded: toolbar.highlighted !== homeBtn.text

          onActivated: {
            toolbar.highlighted = homeBtn.text;
            if (authPanel.visible)
              authPanel.close()
            showMergin = false
          }
        }
      }

      Item {
        width: parent.width/parent.children.length
        height: parent.height
        MainPanelButton {
          id: myProjectsBtn
          width: toolbar.itemSize
          text: qsTr("My projects")
          imageSource: "account.svg"
          faded: toolbar.highlighted !== myProjectsBtn.text

          onActivated: {
            toolbar.highlighted = myProjectsBtn.text
            busyIndicator.running = true
            showMergin = true
            __merginApi.listProjects("", "created")
          }
        }
      }

      Item {
        width: parent.width/parent.children.length
        height: parent.height
        MainPanelButton {
          id: sharedProjectsBtn
          width: toolbar.itemSize
          text: parent.width > sharedProjectsBtn.width * 2 ? qsTr("Shared with me") : qsTr("Shared")
          imageSource: "account-multi.svg"
          faded: toolbar.highlighted !== sharedProjectsBtn.text

          onActivated: {
            toolbar.highlighted = sharedProjectsBtn.text
            busyIndicator.running = true
            showMergin = true
            __merginApi.listProjects("", "shared")
          }
        }
      }

      Item {
        width: parent.width/parent.children.length
        height: parent.height
        MainPanelButton {
          id: exploreBtn
          width: toolbar.itemSize
          text: qsTr("Explore")
          imageSource: "explore.svg"
          faded: toolbar.highlighted !== exploreBtn.text

          onActivated: {
            toolbar.highlighted = exploreBtn.text
            busyIndicator.running = true
            showMergin = true
            authPanel.visible = false
            __merginApi.listProjects( searchBar.text )
          }
        }
      }
    }
  }

  // Other components
  AuthPanel {
    id: authPanel
    visible: false
    y: searchBar.y
    height: contentLayout.height + searchBar.height
    width: parent.width
    onAuthFailed: homeBtn.activated()
    toolbarHeight: toolbar.height
    onPendingChanged: busyIndicator.running = authPanel.pending

    onVisibleChanged: {
      if (!authPanel.visible)
      {
        // gain focus if auth panel is closed
        projectsPanel.forceActiveFocus()
      }
    }
  }

  AccountPage {
    id: accountPanel
    height: parent.height
    width: parent.width
    visible: false
    onBackClicked: {
      accountPanel.visible = false
      subscribePanel.visible = false
    }
    onManagePlansClicked: {
      if (__purchasing.hasInAppPurchases && (__purchasing.hasManageSubscriptionCapability || !__merginApi.userInfo.ownsActiveSubscription )) {
        subscribePanel.visible = true
        accountPanel.visible = false
      } else {
        Qt.openUrlExternally(__purchasing.subscriptionManageUrl);
      }
    }
    onSignOutClicked: {
      if (__merginApi.userAuth.hasAuthData()) {
        __merginApi.clearAuth()
        accountPanel.visible = false
        subscribePanel.visible = false
      }
    }
    onRestorePurchasesClicked: {
      __purchasing.restore()
    }
  }

  SubscribePage {
    id: subscribePanel
    height: parent.height
    width: parent.width
    visible: false
    onBackClicked: {
      accountPanel.visible = true
      subscribePanel.visible = false
    }
    onSubscribeClicked: {
      accountPanel.visible = true
      subscribePanel.visible = false
    }
  }

  MessageDialog {
    id: deleteDialog
    visible: false
    property int relatedProjectIndex

    title: qsTr( "Remove project" )
    text: qsTr( "Any unsynchronized changes will be lost." )
    icon: StandardIcon.Warning
    standardButtons: StandardButton.Ok | StandardButton.Cancel

    //! Using onButtonClicked instead of onAccepted,onRejected which have been called twice
    onButtonClicked: {
        if (clickedButton === StandardButton.Ok) {
          if (relatedProjectIndex < 0) {
              return;
          }
          __projectsModel.deleteProject(relatedProjectIndex)
          if (projectsPanel.activeProjectIndex === relatedProjectIndex) {
            __loader.load("")
            projectsPanel.activeProjectIndex = -1
          }
          deleteDialog.relatedProjectIndex = -1
          visible = false
        }
        else if (clickedButton === StandardButton.Cancel) {
          deleteDialog.relatedProjectIndex = -1
          visible = false
        }
    }
  }

  Item {
    id: reloadList
    width: parent.width
    height: grid.cellHeight
    visible: false
    Layout.alignment: Qt.AlignVCenter
    y: projectsPanel.height/3 * 2

    Button {
        id: reloadBtn
        width: reloadList.width - 2* InputStyle.panelMargin
        height: reloadList.height
        text: qsTr("Retry")
        font.pixelSize: reloadBtn.height/2
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
          busyIndicator.running = true
          // filters suppose to not change
          __merginApi.listProjects( searchBar.text )
          reloadList.visible = false
        }
        background: Rectangle {
            color: InputStyle.highlightColor
        }

        contentItem: Text {
            text: reloadBtn.text
            font: reloadBtn.font
            color: InputStyle.clrPanelMain
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
  }

  ProjectStatusPanel {
    id: statusPanel
    anchors.fill: parent
    visible: false
  }
}
