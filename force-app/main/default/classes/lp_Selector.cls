/**
 * @author Ladd Partners
 * @date 2/07/2017
 * @group
*/
public virtual class lp_Selector {

    private String sobjName;
    private Set<String> fields;

    public lp_Selector() {
        fields = new Set<String>();
    }

    public void setSObjectType(Schema.SObjectType sobjType) {
        sobjName = sobjType.getDescribe().getName();
    }

    public void setSObjectType(String sobjType) {
        sobjName = sobjType;
    }

    public void addField(Schema.SObjectField field) {
        fields.add(field.getDescribe().getName());
    }

    public void addField(String fieldName) {
        fields.add(fieldName);
    }
    
    public String getSelectStatement() {
        return getSelect() + ' ' + getFrom();
    }

    public String getSelectStatement(String subSelect) {
        return getSelectStatement(new List<String>{subSelect});
    }

    public String getSelectStatement(List<String> subSelects) {
        String selectstatement = '';
        selectstatement += getSelect();

        if (subSelects != null && !subSelects.isEmpty()) {
            for (String subSelect : subSelects) {
                selectstatement += ', (' + subSelect + ')';
            }
        }

        return selectstatement + ' ' + getFrom();
    }

    public String getSelect() {
        return 'SELECT ' + getFields();
    }

    private String getFrom() {
        return 'FROM ' + sobjName;
    }

    private String getFields() {
        String selectFields = '';

        for (String field : fields) {
            if (selectFields.length() > 0) {
                selectFields += ', ';
            }
            selectFields += field;
        }

        return selectFields;
    }
}