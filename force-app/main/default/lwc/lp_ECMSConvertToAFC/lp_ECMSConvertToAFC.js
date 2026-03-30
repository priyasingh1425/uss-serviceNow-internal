import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import convertEcmsToAfc from '@salesforce/apex/lp_EcmsCertificateController.rerunAFCExemptionCreation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class LpEcmsConvertToAfc extends LightningElement {
    @track loading = false;
    @track errorMessage;
    @track isSuccessful = false;
    @track errorOccur = false;

    connectedCallback() {
        this.convertEcmsToAfcExemption();
    }

    convertEcmsToAfcExemption(){
        this.loading = true;
        convertEcmsToAfc()
        .then(result => {
            if(result.isSuccessful) {
                this.showToast('Success', result.message, 'success');
                this.close();
            } else {
                this.errorMessage = result.message;
                this.errorOccur = true;
            }
            this.loading = false;
        })
        .catch(error => {
            this.errorMessage = 'Issue starting ECMS Conversion batch';
            if (error.body) { this.errorMessage = error.body.message};
            this.loading = false;
        });
    }

    close() {
        setTimeout(
            function() {
                window.history.back();
            },
            1000
        );
    }

    showToast(t, m, v) {
        const evt = new ShowToastEvent({
            title: t,
            message: m,
            variant: v,
        });
        this.dispatchEvent(evt);
    }

}