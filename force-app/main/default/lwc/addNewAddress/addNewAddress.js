import { LightningElement, wire, track,api } from 'lwc';
import searchRecords from '@salesforce/apex/API_CB_AutoCompleteAddress_QRY.autocompleteAddress';
import editQuoteAddress from '@salesforce/apex/API_CB_AutoCompleteAddress_QRY.editQuoteAddress';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import QLG_ZIP_FIELD from "@salesforce/schema/SBQQ__QuoteLineGroup__c.Zip__c";
import QLG_STREET_FIELD from "@salesforce/schema/SBQQ__QuoteLineGroup__c.Street__c";
import QLG_STATE_FIELD from "@salesforce/schema/SBQQ__QuoteLineGroup__c.State__c";
import QLG_COUNTRY_FIELD from "@salesforce/schema/SBQQ__QuoteLineGroup__c.Country__c";
import QLG_CITY_FIELD from "@salesforce/schema/SBQQ__QuoteLineGroup__c.City__c";
import QLG_NAME_FIELD from "@salesforce/schema/SBQQ__QuoteLineGroup__c.Name";
import QA_ZIP_FIELD from "@salesforce/schema/Quote_Address__c.Zip__c";
import QA_STREET_FIELD from "@salesforce/schema/Quote_Address__c.Street__c";
import QA_STATE_FIELD from "@salesforce/schema/Quote_Address__c.State__c";
import QA_COUNTRY_FIELD from "@salesforce/schema/Quote_Address__c.Country__c";
import QA_CITY_FIELD from "@salesforce/schema/Quote_Address__c.City__c";
import QA_NAME_FIELD from "@salesforce/schema/Quote_Address__c.Name";

// SC-0000100
// Get complete address from connectbase.

export default class AddNewAddress extends LightningElement {
    @api status;
    @api searchTerm = '';
    @api searchTerm2 = '';
    @track searchResults = [];
    @track searchResults2 = [];
    @track selectedRecord = null;
    @track selectedRecord2 = null;
    @api street;
    @api city;
    @api country;
    @api state;
    @api zipcode;
    @api a_address=false;
    @api z_address=false;
    @api z_street;
    @api z_city;
    @api z_country;
    @api z_state;
    @api z_zipcode;
    @track showPopup = false;
    currentPageReference;
    @track isQuickAction = false;
    @track qlgRecordId = '';
    fields = [];
    objectAPIName = '';
    @track oldAddress = '';
    isOffNet = false;
    On_Net_options=[{label:'On-Net Value',value:'On-Net Value'}];

    @wire(CurrentPageReference) currentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if(this.currentPageReference.type == 'standard__quickAction'){
            this.isQuickAction = true;
            this.qlgRecordId = this.currentPageReference.state.recordId;  
            this.objectAPIName = this.currentPageReference.attributes.apiName;;  
            console.log('API Name',this.objectAPIName);
            

            this.setFields();   
            
        }
       
        
      }


      setFields() {
        // Dynamically set the fields array based on objectApiName
        console.log(this.objectAPIName);
        
        if (this.objectAPIName == 'Quote_Address__c.Edit_Address') {
            console.log('inside');
            
            this.fields = [
                QA_STREET_FIELD,
                QA_CITY_FIELD,
                QA_STATE_FIELD,
                QA_COUNTRY_FIELD,
                QA_ZIP_FIELD,
                QA_NAME_FIELD
            ];
        } else if (this.objectAPIName == 'SBQQ__QuoteLineGroup__c.Edit_Address') {
            this.fields = [
                QLG_STREET_FIELD,
                QLG_CITY_FIELD,
                QLG_STATE_FIELD,
                QLG_COUNTRY_FIELD,
                QLG_ZIP_FIELD,
                QLG_NAME_FIELD
            ];
        } else {
            console.warn(`Unsupported objectApiName: ${this.objectApiName}`);
        }
    }


      @wire(getRecord, { recordId: "$qlgRecordId", fields: "$fields" })
      record({ error, data }) {
        if (data) {
          // Assign the field values to @api properties
          this.street = data.fields.Street__c.value;
          this.city = data.fields.City__c.value;
          this.country = data.fields.Country__c.value;
          this.state = data.fields.State__c.value;
          this.zipcode = data.fields.Zip__c.value;
          this.oldAddress = this.street+','+ this.city+','+  this.state+','+  this.country+','+  this.zipcode;
        } else if (error) {
          console.error("Error fetching record:", error);
        }
      }
    

    handleSearch(event) {
        this.searchResults = [];
        const searchValue = event.target.value.trim();
        this.searchTerm = searchValue;
      
        if (searchValue.length >= 3) {
            this.searchResults = [];
            searchRecords({ search: searchValue,preferred_states : '', preferred_cities: ''})
            .then((response) => {

                if (searchValue !== this.searchTerm) {
                    return; 
                }

                if(response.length > 0){
            
                    this.searchResults = response.map((item,index) => ({
                        id: index, 
                        displayText: `${item.address}, ${item.city}, ${item.state}, ${item.country}, ${item.zipcode || ''}`.trim(),
                        street : item.address,
                        city : item.city,
                        state: item.state,
                        country: item.country,
                        zipcode: item.zipcode
                }))
                }else{
                    this.searchResults = [];
                    this.issearchResults = false;
                }
               
                
            })
            .catch((error) => {
                console.error('Error fetching search results:', error);
                this.searchResults = [];
               
            });
        } 
        else {
            this.searchResults = [];
           
        }
    }

    handleSearch2(event) {
        this.searchResults2 = [];
        const searchValue2 = event.target.value.trim();

        this.searchTerm2 = searchValue2;

        if (searchValue2.length >= 3) {
            this.searchResults2 = [];
            console.log('search value: ' , searchValue2);
            searchRecords({ search:searchValue2,preferred_states : '', preferred_cities: ''})
            .then((result) => {
                if (searchValue2 !== this.searchTerm2) {
                    return; 
                }
                if(result.length > 0){
                    this.searchResults2 = result.map((item,index) => ({
                        id: index, 
                        displayText: `${item.address}, ${item.city}, ${item.state}, ${item.country}, ${item.zipcode || ''}`.trim(),
                        street: item.address,
                        city : item.city,
                        state: item.state,
                        country: item.country,
                        zipcode: item.zipcode
                }))
                console.log('this.searchResults2: ', this.searchResults2);
                console.log('List Size ',this.searchResults2.length);
                }else{
                    this.searchResults2 = [];
                }
                

             
            })
            .catch((error) => {
                console.error('Error fetching search results:', error);
                this.searchResults2 = [];
            });
        } 
        else {
            this.searchResults2 = [];
        }
    }

    handleSelect(event) {
        const recordId = event.currentTarget.dataset.id; 
        const displayValue = event.currentTarget.dataset.value; 

        this.selectedRecord = { id: recordId, displayText: displayValue };
        this.searchTerm = displayValue; 

        if(recordId != null){
            const selectedData = this.searchResults.find(item => item.id == recordId);
            console.log('selectedData >>>> ', selectedData);
            if(selectedData){
                this.street = selectedData.street;
                this.city = selectedData.city;
                this.country = selectedData.country;
                this.zipcode = selectedData.zipcode;
                this.state = selectedData.state;
                this.searchTerm = selectedData.displayText;
            }
        }

        const selectionEvent = new CustomEvent('recordselect', {
            detail: this.selectedRecord,
        });
        this.dispatchEvent(selectionEvent);
        this.searchResults = [];

    }

    handleSelect2(event) {
       
            
        
        const recordId = event.currentTarget.dataset.id; 
        const displayValue = event.currentTarget.dataset.value; 
        
        this.selectedRecord2 = { id: recordId, displayText: displayValue };
        this.searchTerm2 = displayValue; 

        if(recordId != null){
            console.log('this.searchResults2 >>>> ', this.searchResults2);
            
            let selectedData = this.searchResults2.find(item => item.id == recordId);
            console.log('selectedData >>>> ', selectedData);
            
            if(selectedData){
                this.z_street = selectedData.street;
                this.z_city = selectedData.city;
                this.z_country = selectedData.country;
                this.z_zipcode = selectedData.zipcode;
                this.z_state = selectedData.state;
                this.searchTerm2 = selectedData.displayText;
            }
        }

        const selectionEvent = new CustomEvent('recordselect', {
            detail: this.selectedRecord2,
        });
        this.dispatchEvent(selectionEvent);
        this.searchResults2 = [];
    

    }

    handleInputChange(event){
          if(event.target.name == 'street'){
              this.street = event.target.value;
          }else if(event.target.name == 'city'){
              this.city = event.target.value;
          }else if(event.target.name == 'state'){
              this.state = event.target.value;
          }else if(event.target.name == 'country'){
              this.country = event.target.value;
          }else if(event.target.name == 'zipcode'){
              this.zipcode = event.target.value;
          }else if(event.target.name == 'a-address'){
           // if (this.street && this.city && this.state && this.country && this.zipcode) {
                this.a_address = event.target.checked;
                this.z_address = event.target.checked; // Sync with z_address
            // } else {
            //     this.showToast('Error', 'Please fill A Address value', 'error');
                
            // }
          }else  if(event.target.name == 'z-street'){
            this.z_street = event.target.value;
        }else if(event.target.name == 'z-city'){
            this.z_city = event.target.value;
        }else if(event.target.name == 'z-state'){
            this.z_state = event.target.value;
        }else if(event.target.name == 'z-country'){
            this.z_country = event.target.value;
        }else if(event.target.name == 'z-zipcode'){
            this.z_zipcode = event.target.value;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, 
        });
        this.dispatchEvent(event);
    }

    handleSave(){
       if (this.objectAPIName == 'SBQQ__QuoteLineGroup__c.Edit_Address'){
            editQLGAddress({recordId:this.qlgRecordId,serach:this.searchTerm,street:this.street,city:this.city,state:this.state,country:this.country,zipcode:this.zipcode})
            .then((result) => {
                console.log('result: ', result);
              
                if(result == 'Address updated successfully'){
                    this.showToast('Success', result, 'success');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                    this.showToast('Error', result, 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
                
                .catch((error) => {
                    console.log('error: ', error);
                    this.showToast('Error', 'Error updating record', 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                });

            
        }else if(this.objectAPIName == 'Quote_Address__c.Edit_Address'){
            console.log('Old Address',this.oldAddress);
            
            editQuoteAddress({recordId:this.qlgRecordId,serach:this.searchTerm,street:this.street,city:this.city,state:this.state,country:this.country,zipcode:this.zipcode,oldAddress:this.oldAddress})
            .then((result) => {
                console.log('result: ', result);
              
                if(result == 'Address updated successfully'){
                    this.showToast('Success', result, 'success');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                    this.showToast('Error', result, 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
                
                .catch((error) => {
                    console.log('error: ', error);
                    this.showToast('Error', 'Error updating record', 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                });
        }
       
    }
}