global class BNR_SObject_BackColor_OPT extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('Red', 'RED');
        return defaultValue;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DataRow value1 = new VisualEditor.DataRow('Red', 'RED');
        VisualEditor.DataRow value2 = new VisualEditor.DataRow('Orange', 'ORANGE');
        VisualEditor.DataRow value3 = new VisualEditor.DataRow('Yellow', 'YELLOW');
        VisualEditor.DataRow value4 = new VisualEditor.DataRow('Green', 'GREEN');
        VisualEditor.DataRow value5 = new VisualEditor.DataRow('Grey', 'GREY');
        VisualEditor.DataRow value6 = new VisualEditor.DataRow('Black', 'BLACK');
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        myValues.addRow(value1);
        myValues.addRow(value2);
        myValues.addRow(value3);
        myValues.addRow(value4);
        myValues.addRow(value5);
        myValues.addRow(value6);
        return myValues;
    }
}