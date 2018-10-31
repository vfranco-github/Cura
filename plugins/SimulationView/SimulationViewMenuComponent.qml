// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.4
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.0 as UM
import Cura 1.0 as Cura

Item
{
    id: base
    width:
    {
        if (UM.SimulationView.compatibilityMode)
        {
            return UM.Theme.getSize("layerview_menu_size_compatibility").width;
        }
        else
        {
            return UM.Theme.getSize("layerview_menu_size").width;
        }
    }
    height: {
        if (viewSettings.collapsed)
        {
            if (UM.SimulationView.compatibilityMode)
            {
                return UM.Theme.getSize("layerview_menu_size_compatibility_collapsed").height;
            }
            return UM.Theme.getSize("layerview_menu_size_collapsed").height;
        }
        else if (UM.SimulationView.compatibilityMode)
        {
            return UM.Theme.getSize("layerview_menu_size_compatibility").height;
        }
        else if (UM.Preferences.getValue("layerview/layer_view_type") == 0)
        {
            return UM.Theme.getSize("layerview_menu_size_material_color_mode").height + UM.SimulationView.extruderCount * (UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("layerview_row_spacing").height)
        }
        else
        {
            return UM.Theme.getSize("layerview_menu_size").height + UM.SimulationView.extruderCount * (UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("layerview_row_spacing").height)
        }
    }
    Behavior on height { NumberAnimation { duration: 100 } }

    property var buttonTarget:
    {
        if(parent != null)
        {
            var force_binding = parent.y; // ensure this gets reevaluated when the panel moves
            return base.mapFromItem(parent.parent, parent.buttonTarget.x, parent.buttonTarget.y)
        }
        return Qt.point(0,0)
    }

    Rectangle
    {
        id: layerViewMenu
        anchors.right: parent.right
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        clip: true
        z: layerSlider.z - 1
        color: UM.Theme.getColor("tool_panel_background")
        border.width: UM.Theme.getSize("default_lining").width
        border.color: UM.Theme.getColor("lining")

        Button
        {
            id: collapseButton
            anchors.top: parent.top
            anchors.topMargin: Math.round(UM.Theme.getSize("default_margin").height + (UM.Theme.getSize("layerview_row").height - UM.Theme.getSize("default_margin").height) / 2)
            anchors.right: parent.right
            anchors.rightMargin: UM.Theme.getSize("default_margin").width

            width: UM.Theme.getSize("standard_arrow").width
            height: UM.Theme.getSize("standard_arrow").height

            onClicked: viewSettings.collapsed = !viewSettings.collapsed

            style: ButtonStyle
            {
                background: UM.RecolorImage
                {
                    width: control.width
                    height: control.height
                    sourceSize.width: width
                    sourceSize.height: width
                    color:  UM.Theme.getColor("setting_control_text")
                    source: viewSettings.collapsed ? UM.Theme.getIcon("arrow_left") : UM.Theme.getIcon("arrow_bottom")
                }
                label: Label{ }
            }
        }

        Column
        {
            id: viewSettings

            property bool collapsed: false
            property var extruder_opacities: UM.Preferences.getValue("layerview/extruder_opacities").split("|")
            property bool show_travel_moves: UM.Preferences.getValue("layerview/show_travel_moves")
            property bool show_helpers: UM.Preferences.getValue("layerview/show_helpers")
            property bool show_skin: UM.Preferences.getValue("layerview/show_skin")
            property bool show_infill: UM.Preferences.getValue("layerview/show_infill")
            // if we are in compatibility mode, we only show the "line type"
            property bool show_legend: UM.SimulationView.compatibilityMode ? true : UM.Preferences.getValue("layerview/layer_view_type") == 1
            property bool show_gradient: UM.SimulationView.compatibilityMode ? false : UM.Preferences.getValue("layerview/layer_view_type") == 2 || UM.Preferences.getValue("layerview/layer_view_type") == 3
            property bool show_feedrate_gradient: show_gradient && UM.Preferences.getValue("layerview/layer_view_type") == 2
            property bool show_thickness_gradient: show_gradient && UM.Preferences.getValue("layerview/layer_view_type") == 3
            property bool only_show_top_layers: UM.Preferences.getValue("view/only_show_top_layers")
            property int top_layer_count: UM.Preferences.getValue("view/top_layer_count")

            anchors.top: parent.top
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            anchors.right: parent.right
            anchors.rightMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("layerview_row_spacing").height

            Label
            {
                id: layerViewTypesLabel
                text: catalog.i18nc("@label","Color scheme")
                font: UM.Theme.getFont("default");
                visible: !UM.SimulationView.compatibilityMode
                width: parent.width
                color: UM.Theme.getColor("setting_control_text")
            }

            ListModel  // matches SimulationView.py
            {
                id: layerViewTypes
            }

            Component.onCompleted:
            {
                layerViewTypes.append({
                    text: catalog.i18nc("@label:listbox", "Material Color"),
                    type_id: 0
                })
                layerViewTypes.append({
                    text: catalog.i18nc("@label:listbox", "Line Type"),
                    type_id: 1
                })
                layerViewTypes.append({
                    text: catalog.i18nc("@label:listbox", "Feedrate"),
                    type_id: 2
                })
                layerViewTypes.append({
                    text: catalog.i18nc("@label:listbox", "Layer thickness"),
                    type_id: 3  // these ids match the switching in the shader
                })
            }

            ComboBox
            {
                id: layerTypeCombobox
                width: parent.width
                model: layerViewTypes
                visible: !UM.SimulationView.compatibilityMode
                style: UM.Theme.styles.combobox

                onActivated:
                {
                    UM.Preferences.setValue("layerview/layer_view_type", index);
                }

                Component.onCompleted:
                {
                    currentIndex = UM.SimulationView.compatibilityMode ? 1 : UM.Preferences.getValue("layerview/layer_view_type");
                    updateLegends(currentIndex);
                }

                function updateLegends(type_id)
                {
                    // update visibility of legends
                    viewSettings.show_legend = UM.SimulationView.compatibilityMode || (type_id == 1);
                    viewSettings.show_gradient = !UM.SimulationView.compatibilityMode && (type_id == 2 || type_id == 3);
                    viewSettings.show_feedrate_gradient = viewSettings.show_gradient && (type_id == 2);
                    viewSettings.show_thickness_gradient = viewSettings.show_gradient && (type_id == 3);
                }
            }

            Label
            {
                id: compatibilityModeLabel
                text: catalog.i18nc("@label","Compatibility Mode")
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
                visible: UM.SimulationView.compatibilityMode
                height: UM.Theme.getSize("layerview_row").height
                width: parent.width
            }

            Item
            {
                height: Math.round(UM.Theme.getSize("default_margin").width / 2)
                width: width
            }

            Connections
            {
                target: UM.Preferences
                onPreferenceChanged:
                {
                    layerTypeCombobox.currentIndex = UM.SimulationView.compatibilityMode ? 1 : UM.Preferences.getValue("layerview/layer_view_type");
                    layerTypeCombobox.updateLegends(layerTypeCombobox.currentIndex)
                    viewSettings.extruder_opacities = UM.Preferences.getValue("layerview/extruder_opacities").split("|")
                    viewSettings.show_travel_moves = UM.Preferences.getValue("layerview/show_travel_moves")
                    viewSettings.show_helpers = UM.Preferences.getValue("layerview/show_helpers")
                    viewSettings.show_skin = UM.Preferences.getValue("layerview/show_skin")
                    viewSettings.show_infill = UM.Preferences.getValue("layerview/show_infill")
                    viewSettings.only_show_top_layers = UM.Preferences.getValue("view/only_show_top_layers")
                    viewSettings.top_layer_count = UM.Preferences.getValue("view/top_layer_count")
                }
            }

            Repeater
            {
                model: Cura.ExtrudersModel{}
                CheckBox
                {
                    id: extrudersModelCheckBox
                    checked: viewSettings.extruder_opacities[index] > 0.5 || viewSettings.extruder_opacities[index] == undefined || viewSettings.extruder_opacities[index] == ""
                    onClicked:
                    {
                        viewSettings.extruder_opacities[index] = checked ? 1.0 : 0.0
                        UM.Preferences.setValue("layerview/extruder_opacities", viewSettings.extruder_opacities.join("|"));
                    }
                    visible: !UM.SimulationView.compatibilityMode
                    enabled: index + 1 <= 4
                    Rectangle
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: extrudersModelCheckBox.right
                        width: UM.Theme.getSize("layerview_legend_size").width
                        height: UM.Theme.getSize("layerview_legend_size").height
                        color: model.color
                        radius: Math.round(width / 2)
                        border.width: UM.Theme.getSize("default_lining").width
                        border.color: UM.Theme.getColor("lining")
                        visible: !viewSettings.show_legend & !viewSettings.show_gradient
                    }
                    height: UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("default_lining").height
                    width: parent.width

                    style: UM.Theme.styles.checkbox
                    Label
                    {
                        text: model.name
                        elide: Text.ElideRight
                        color: UM.Theme.getColor("setting_control_text")
                        font: UM.Theme.getFont("default")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: extrudersModelCheckBox.left
                        anchors.right: extrudersModelCheckBox.right
                        anchors.leftMargin: UM.Theme.getSize("checkbox").width + Math.round(UM.Theme.getSize("default_margin").width / 2)
                        anchors.rightMargin: UM.Theme.getSize("default_margin").width * 2
                    }
                }
            }

            Repeater
            {
                model: ListModel
                {
                    id: typesLegendModel
                    Component.onCompleted:
                    {
                        typesLegendModel.append({
                            label: catalog.i18nc("@label", "Show Travels"),
                            initialValue: viewSettings.show_travel_moves,
                            preference: "layerview/show_travel_moves",
                            colorId:  "layerview_move_combing"
                        });
                        typesLegendModel.append({
                            label: catalog.i18nc("@label", "Show Helpers"),
                            initialValue: viewSettings.show_helpers,
                            preference: "layerview/show_helpers",
                            colorId:  "layerview_support"
                        });
                        typesLegendModel.append({
                            label: catalog.i18nc("@label", "Show Shell"),
                            initialValue: viewSettings.show_skin,
                            preference: "layerview/show_skin",
                            colorId:  "layerview_inset_0"
                        });
                        typesLegendModel.append({
                            label: catalog.i18nc("@label", "Show Infill"),
                            initialValue: viewSettings.show_infill,
                            preference: "layerview/show_infill",
                            colorId:  "layerview_infill"
                        });
                    }
                }

                CheckBox
                {
                    id: legendModelCheckBox
                    checked: model.initialValue
                    onClicked:
                    {
                        UM.Preferences.setValue(model.preference, checked);
                    }
                    Rectangle
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: legendModelCheckBox.right
                        width: UM.Theme.getSize("layerview_legend_size").width
                        height: UM.Theme.getSize("layerview_legend_size").height
                        color: UM.Theme.getColor(model.colorId)
                        border.width: UM.Theme.getSize("default_lining").width
                        border.color: UM.Theme.getColor("lining")
                        visible: viewSettings.show_legend
                    }
                    height: UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("default_lining").height
                    width: parent.width
                    style: UM.Theme.styles.checkbox
                    Label
                    {
                        text: label
                        font: UM.Theme.getFont("default")
                        elide: Text.ElideRight
                        color: UM.Theme.getColor("setting_control_text")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: legendModelCheckBox.left
                        anchors.right: legendModelCheckBox.right
                        anchors.leftMargin: UM.Theme.getSize("checkbox").width + Math.round(UM.Theme.getSize("default_margin").width / 2)
                        anchors.rightMargin: UM.Theme.getSize("default_margin").width * 2
                    }
                }
            }

            CheckBox
            {
                checked: viewSettings.only_show_top_layers
                onClicked:
                {
                    UM.Preferences.setValue("view/only_show_top_layers", checked ? 1.0 : 0.0)
                }
                text: catalog.i18nc("@label", "Only Show Top Layers")
                visible: UM.SimulationView.compatibilityMode
                style: UM.Theme.styles.checkbox
            }
            CheckBox
            {
                checked: viewSettings.top_layer_count == 5
                onClicked:
                {
                    UM.Preferences.setValue("view/top_layer_count", checked ? 5 : 1)
                }
                text: catalog.i18nc("@label", "Show 5 Detailed Layers On Top")
                visible: UM.SimulationView.compatibilityMode
                style: UM.Theme.styles.checkbox
            }

            Repeater
            {
                model: ListModel
                {
                    id: typesLegendModelNoCheck
                    Component.onCompleted:
                    {
                        typesLegendModelNoCheck.append({
                            label: catalog.i18nc("@label", "Top / Bottom"),
                            colorId: "layerview_skin",
                        });
                        typesLegendModelNoCheck.append({
                            label: catalog.i18nc("@label", "Inner Wall"),
                            colorId: "layerview_inset_x",
                        });
                    }
                }

                Label
                {
                    text: label
                    visible: viewSettings.show_legend
                    id: typesLegendModelLabel
                    Rectangle
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: typesLegendModelLabel.right
                        width: UM.Theme.getSize("layerview_legend_size").width
                        height: UM.Theme.getSize("layerview_legend_size").height
                        color: UM.Theme.getColor(model.colorId)
                        border.width: UM.Theme.getSize("default_lining").width
                        border.color: UM.Theme.getColor("lining")
                        visible: viewSettings.show_legend
                    }
                    height: UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("default_lining").height
                    width: parent.width
                    color: UM.Theme.getColor("setting_control_text")
                    font: UM.Theme.getFont("default")
                }
            }

            // Text for the minimum, maximum and units for the feedrates and layer thickness
            Item
            {
                id: gradientLegend
                visible: viewSettings.show_gradient
                width: parent.width
                height: UM.Theme.getSize("layerview_row").height

                Label
                {
                    text: minText()
                    anchors.left: parent.left
                    color: UM.Theme.getColor("setting_control_text")
                    font: UM.Theme.getFont("default")

                    function minText()
                    {
                        if (UM.SimulationView.layerActivity && CuraApplication.platformActivity)
                        {
                            // Feedrate selected
                            if (UM.Preferences.getValue("layerview/layer_view_type") == 2)
                            {
                                return parseFloat(UM.SimulationView.getMinFeedrate()).toFixed(2)
                            }
                            // Layer thickness selected
                            if (UM.Preferences.getValue("layerview/layer_view_type") == 3)
                            {
                                return parseFloat(UM.SimulationView.getMinThickness()).toFixed(2)
                            }
                        }
                        return catalog.i18nc("@label","min")
                    }
                }

                Label
                {
                    text: unitsText()
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: UM.Theme.getColor("setting_control_text")
                    font: UM.Theme.getFont("default")

                    function unitsText()
                    {
                        if (UM.SimulationView.layerActivity && CuraApplication.platformActivity)
                        {
                            // Feedrate selected
                            if (UM.Preferences.getValue("layerview/layer_view_type") == 2)
                            {
                                return "mm/s"
                            }
                            // Layer thickness selected
                            if (UM.Preferences.getValue("layerview/layer_view_type") == 3)
                            {
                                return "mm"
                            }
                        }
                        return ""
                    }
                }

                Label
                {
                    text: maxText()
                    anchors.right: parent.right
                    color: UM.Theme.getColor("setting_control_text")
                    font: UM.Theme.getFont("default")

                    function maxText()
                    {
                        if (UM.SimulationView.layerActivity && CuraApplication.platformActivity)
                        {
                            // Feedrate selected
                            if (UM.Preferences.getValue("layerview/layer_view_type") == 2)
                            {
                                return parseFloat(UM.SimulationView.getMaxFeedrate()).toFixed(2)
                            }
                            // Layer thickness selected
                            if (UM.Preferences.getValue("layerview/layer_view_type") == 3)
                            {
                                return parseFloat(UM.SimulationView.getMaxThickness()).toFixed(2)
                            }
                        }
                        return catalog.i18nc("@label","max")
                    }
                }
            }

            // Gradient colors for feedrate
            Rectangle
            {   // In QML 5.9 can be changed by LinearGradient
                // Invert values because then the bar is rotated 90 degrees
                id: feedrateGradient
                visible: viewSettings.show_feedrate_gradient
                anchors.left: parent.right
                height: parent.width
                width: Math.round(UM.Theme.getSize("layerview_row").height * 1.5)
                border.width: UM.Theme.getSize("default_lining").width
                border.color: UM.Theme.getColor("lining")
                transform: Rotation {origin.x: 0; origin.y: 0; angle: 90}
                gradient: Gradient
                {
                    GradientStop
                    {
                        position: 0.000
                        color: Qt.rgba(1, 0.5, 0, 1)
                    }
                    GradientStop
                    {
                        position: 0.625
                        color: Qt.rgba(0.375, 0.5, 0, 1)
                    }
                    GradientStop
                    {
                        position: 0.75
                        color: Qt.rgba(0.25, 1, 0, 1)
                    }
                    GradientStop
                    {
                        position: 1.0
                        color: Qt.rgba(0, 0, 1, 1)
                    }
                }
            }

            // Gradient colors for layer thickness (similar to parula colormap)
            Rectangle // In QML 5.9 can be changed by LinearGradient
            {
                // Invert values because then the bar is rotated 90 degrees
                id: thicknessGradient
                visible: viewSettings.show_thickness_gradient
                anchors.left: parent.right
                height: parent.width
                width: Math.round(UM.Theme.getSize("layerview_row").height * 1.5)
                border.width: UM.Theme.getSize("default_lining").width
                border.color: UM.Theme.getColor("lining")
                transform: Rotation {origin.x: 0; origin.y: 0; angle: 90}
                gradient: Gradient
                {
                    GradientStop
                    {
                        position: 0.000
                        color: Qt.rgba(1, 1, 0, 1)
                    }
                    GradientStop
                    {
                        position: 0.25
                        color: Qt.rgba(1, 0.75, 0.25, 1)
                    }
                    GradientStop
                    {
                        position: 0.5
                        color: Qt.rgba(0, 0.75, 0.5, 1)
                    }
                    GradientStop
                    {
                        position: 0.75
                        color: Qt.rgba(0, 0.375, 0.75, 1)
                    }
                    GradientStop
                    {
                        position: 1.0
                        color: Qt.rgba(0, 0, 0.5, 1)
                    }
                }
            }
        }
    }

    FontMetrics
    {
        id: fontMetrics
        font: UM.Theme.getFont("default")
    }
}
