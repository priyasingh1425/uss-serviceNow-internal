import { LightningElement, api, wire } from "lwc";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";

export default class Om_orderLines extends LightningElement {
  @api recordId;

  records = [];
  recordMap = new Map();

  @wire(getRelatedListRecords, {
    parentRecordId: "$recordId",
    relatedListId: "OrderItems",
    fields: [
      "OrderItem.Product2.Name",
      "OrderItem.Product2.OM_Field_Sets_Order_Item__c",
      "OrderItem.SBQQ__RequiredBy__c",
      "OrderItem.Id"
    ],
    sortBy: ["OrderItem.OrderItemNumber"]
  })
  handleRecords({ error, data }) {
    if (data) {
      this.records = data.records;
      this.recordMap = new Map();
      this.records.forEach((line) => {
        debugger;
        let key = line.fields.SBQQ__RequiredBy__c.value ?? line.id;
        let mapValue = this.recordMap.get(key);
        if (mapValue == null) {
          mapValue = {
            id: key,
            label: null,
            record: null,
            rows: [],
            fieldSets: []
          };
          this.recordMap.set(key, mapValue);
        }
        if (line.fields.SBQQ__RequiredBy__c.value) {
          mapValue.rows.push({
            id: line.id,
            label: line.fields.Product2.displayValue,
            record: line,
            fieldSets:
              line.fields.Product2.value.fields.OM_Field_Sets_Order_Item__c.value?.split(
                ";"
              )
          });
        } else {
          mapValue.label = line.fields.Product2.displayValue;
          mapValue.fieldSets =
            line.fields.Product2.value.fields.OM_Field_Sets_Order_Item__c.value?.split(
              ";"
            );
          mapValue.record = line;
          mapValue.rows.unshift({
            id: line.id,
            label: "Bundle",
            record: line,
            fieldSets:
              line.fields.Product2.value.fields.OM_Field_Sets_Order_Item__c.value?.split(
                ";"
              )
          });
        }
      });
    }
  }

  get recordMapValues() {
    return this.recordMap.values();
  }
}