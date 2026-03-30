import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCreditLines from '@salesforce/apex/lp_CreateCreditLinesController.createCreditLines';

export default class lp_CreateCreditLines extends LightningElement {
    @api recordId;    
    @api invoke() {
        createCreditLines({ contractId: this.recordId })
            .then(result => {
                this.showToast(`Success`, `All credit lines jobs have been created. Check async job stagings to monitor progress.`, `success`);
            })
            .catch(error => {
                let message = `An unknown error occurred.`;
                if (error.body && error.body.message) {
                    message = error.body.message;
                } else if (error.message) {
                    message = error.message;
                }
                this.showToast(`Error`, message, `error`);
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}