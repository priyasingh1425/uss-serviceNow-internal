import { LightningElement, api, wire } from "lwc";
import getFieldSet from "@salesforce/apex/FieldSet_Util.getFieldSet";

export default class Om_fieldSetData extends LightningElement {
  static renderMode = "light";

  @api objectName;
  @api fieldSetName;

  @wire(getFieldSet, {
    objectName: "$objectName",
    fieldSetName: "$fieldSetName"
  })
  fieldSet;
}