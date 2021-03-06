import QtQuick 2.0
import QtQuick.Controls 2.12

Item {

  property alias handler: valueRelationHandler

  QtObject {
    id: valueRelationHandler

    // pointer to widget from qgis feature form
    property var itemWidget: null

    property var valueRelationOpened: function valueRelationOpened( widget, valueRelationModel ) {
      itemWidget = widget
      if ( valueRelationModel.featuresCount > 4 ) {
        valueRelationPage.visible = true
        valueRelationPage.featuresModel = valueRelationModel
        valueRelationPage.pageTitle = itemWidget.fieldName
      }
      else {
        itemWidget.openCombobox()
      }
    }

    function featureSelected( index ) {
      itemWidget.itemSelected( index )
    }
  }

  id: valueRelationWidget
  anchors.fill: parent

  BrowseDataFeaturesPanel {
    id: valueRelationPage
    visible: false
    anchors.fill: parent

    onBackButtonClicked: {
      valueRelationPage.visible = false
      valueRelationPage.deactivateSearch()
    }

    onFeatureClicked: {
      valueRelationHandler.featureSelected( featureIdx )
      valueRelationPage.visible = false
      valueRelationPage.deactivateSearch()
    }

    onSearchTextChanged: {
      featuresModel.filterExpression = text
    }
  }
}
