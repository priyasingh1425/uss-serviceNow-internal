/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import createMonthlyPayableInvoice from '@salesforce/apex/lp_ITSPayableController.createMonthlyPayableInvoice';

export default class lp_CreateMonthlyPayableInvoice extends NavigationMixin(LightningElement)  {
    _recordId;

    @track loading = false;
    @track errorMessage;
    @track successMessage;
    
    get recordId() {
        return this._recordId;
    }

    @api
    set recordId(value) {
        if(value !== this._recordId) {
            this._recordId = value;
            this.create();
        }
    }

    connectedCallback() {
        this.loading = true;
    }

    create(){
        this.loading = true;
        createMonthlyPayableInvoice({ itsPayableInvoiceId: this.recordId })
        .then(result => {
           var message = result.message;
           this.isSuccessful = result.isSuccessful;
           if(this.isSuccessful == true) {
                this.toastMe('Success', message, 'success');
                this.redirectURL(result.newRecordId);
           } else {
                this.errorMessage = message;
           }
           this.loading = false;
        })
        .catch(error => {
           this.errorMessage = 'Issue with creating payable invoice';
           if (error.body) {this.errorMessage = error.body.message};
           this.loading = false;
        });
    }

    back(){
        this.loading = true;
        this.redirectURL(this.recordId);
    }

    redirectURL(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'c2g__codaPurchaseInvoice__c',
                actionName: 'view'
            }
        });

        getRecordNotifyChange([{recordId: recordId}]);
    }

    toastMe(t, m, v) {
        const evt = new ShowToastEvent({
            title: t,
            message: m,
            variant: v,
        });
        this.dispatchEvent(evt);
    }
}