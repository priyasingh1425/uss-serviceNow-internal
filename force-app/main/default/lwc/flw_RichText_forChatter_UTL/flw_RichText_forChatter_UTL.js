import { LightningElement, api } from 'lwc';

export default class flw_RichText_forChatter_UTL extends LightningElement {
    @api fieldValue =" ";
    @api fieldLabel;
    @api required; 
    @api fieldLength;
    @api visibleLines;
    @api recordId;
    @api validity;
    @api helpMessage;
    

    allowedFormats = [
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'link',
        'image',
        'clean',
    ];

    connectedCallback() {
        this.validity=true;
        document.documentElement.style.setProperty('--rta-visiblelines', (this.visibleLines * 2) + 'em');
    }

    handleChange(event) {
        if((event.target.value).length > this.fieldLength){
            this.validity=false;
            this.errorMessage = "You have exceeded the max length";
        }
       else{
        this.validity = true;
        this.fieldValue = event.target.value;
       }
    }
}