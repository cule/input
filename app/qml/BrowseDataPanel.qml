/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Controls 2.12
import lc 1.0

/*
 * BrowseDataPanel should stay a logic component, please do not combine UI here
 */

Item {
  id: root
  visible: false
  property var selectedLayer: null

  signal featureSelectRequested( var pair )
  signal createFeatureRequested()

  onSelectedLayerChanged: {
    if ( selectedLayer )
      __featuresModel.reloadDataFromLayer( selectedLayer )
  }

  onFocusChanged: { // pass focus to stackview
    browseDataLayout.focus = true
  }

  function clearStackAndClose() {
    if ( browseDataLayout.depth > 1 )
      browseDataLayout.pop( null ) // pops everything besides an initialItem
    root.visible = false
  }

  function popOnePageOrClose() {
    if ( browseDataLayout.depth > 1 )
    {
      browseDataLayout.pop()
    }
    else clearStackAndClose()
  }

  function loadFeaturesFromLayerIndex( layerId ) {
    let layer = __browseDataLayersModel.layerFromLayerId( layerId )

    selectedLayer = layer
  }

  function pushFeaturesPanelWithParams( layerId ) {
    let modelIndex = __browseDataLayersModel.indexFromLayerId( layerId )
    let hasGeometry = __browseDataLayersModel.getData( modelIndex, LayersModel.HasGeometryRole )
    let layerName = __browseDataLayersModel.getData( modelIndex, LayersModel.LayerNameRole )
    let featuresCount = __featuresModel.featuresCount
    let featuresLimit = __featuresModel.featuresLimit

    browseDataLayout.push( browseDataFeaturesPanel, {
                            layerHasGeometry: hasGeometry,
                            layerName: layerName,
                            featuresCount: featuresCount,
                            featuresLimit: featuresLimit
                          } )
  }

  function searchTextEdited( text ) {
    __featuresModel.filterExpression = text
  }

  StackView {
    id: browseDataLayout
    initialItem: browseDataLayersPanel
    anchors.fill: parent
    focus: true

    Keys.onReleased: {
      if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
        event.accepted = true;
        popOnePageOrClose()
      }
    }

    onVisibleChanged: {
      if ( browseDataLayout.visible )
        browseDataLayout.forceActiveFocus()
    }
  }

  Component {
    id: browseDataLayersPanel

    BrowseDataLayersPanel {
      onBackButtonClicked: popOnePageOrClose()
      onLayerClicked: {
        loadFeaturesFromLayerIndex( layerId )
        pushFeaturesPanelWithParams( layerId )
      }
    }
  }

  Component {
    id: browseDataFeaturesPanel

    BrowseDataFeaturesPanel {
      id: dataFeaturesPanel
      onBackButtonClicked: popOnePageOrClose()
      onFeatureClicked: {
        let featurePair = __featuresModel.featureLayerPair( featureId )

        if ( !featurePair.feature.geometry.isNull )
          clearStackAndClose() // close view if feature has geometry

        root.featureSelectRequested( featurePair )
      }
      onAddFeatureClicked: createFeatureRequested()
      onSearchTextChanged: searchTextEdited( text )
    }
  }
}
