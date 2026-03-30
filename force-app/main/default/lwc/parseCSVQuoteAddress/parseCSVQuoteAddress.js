import { LightningElement, wire, api,track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import sampleCSVfile from "@salesforce/resourceUrl/bulkUploadQuoteAddress";
import searchRecords from '@salesforce/apex/API_CB_AutoCompleteAddress_QRY.autocompleteAddressBulk';
import bulkInsert from '@salesforce/apex/API_CB_AutoCompleteAddress_QRY.bulkAddressInsert';
import apiResponseInsert from '@salesforce/apex/API_CB_AutoCompleteAddress_QRY.insertAllAPIResponse';
import {
    FlowNavigationNextEvent
  } from "lightning/flowSupport";
         

// SC-0000100
// uploading and parsing bulk quote addresses from a csv

export default class ParseCSVQuoteAddress extends LightningElement {
    rawData;
    @api recordId;
    fileUrl;
    isSuccess = false;
    isUpload = true;
    @api status;
    isPopup = false;
    isNotPopup = false;
    showAccordian = false;
    @api street;
    @api city;
    @api country;
    @api state;
    @api zipcode;
    @api isFileNotValid=false;
    @api isRecordSaved;
    selectedValues = {};
    @track accordionData = [];
    spinner = false;
    receivedAddresses=[];
    apiResponse = [];

    @wire(CurrentPageReference)
    wirePageRef(data){
        if(data){
            this.recordId = data.attributes.recordId;
        }
    }

    connectedCallback() {
        this.fileUrl = sampleCSVfile;
    }

    handleRadioChange(event){
        const sectionKey = event.target.dataset.sectionKey;
        const selectedValue = event.detail.value;
        this.selectedValues[sectionKey] = selectedValue;
    
        console.log('Updated selected values:', this.selectedValues);

    //     const parts = selectedValue.split(',');

    //     // order will be 1) Opportunity Id, 2) Street, 3) City, 4) State, 5) Country, 6) Zip Code
    //     street = parts[0];
    //     city = parts[1];
    //     state = parts[2];
    //  country = parts[3];
    //  zipcode = parts[4];
     //render for each value
     
    }

    closeModal() {
        this.showAccordian = false;
    }

    confirmSelection() {
    console.log('selectedValues',this.selectedValues);
    const extractedAddresses = Object.values(this.selectedValues)
    
    console.log('Extracted Addresses:', extractedAddresses);
    

     bulkInsert({addressList:extractedAddresses,recordId: this.recordId})
     .then((isSuccess) => {
        if (isSuccess) {
            this.isRecordSaved = true;
            const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
        } else {
            this.isRecordSaved=false;
            const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
        }
    })
    .catch((error) => {
        this.isRecordSaved = false;
        const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
    });

        this.closeModal(); 
    }

    async handleCsvFile(event) {
        this.spinner = true;
        const file = event.target.files[0];
        if (file) {
            await this.parseCSV(file);
            console.log('parsed file: ', this.rawData);
            // insertQuoteAddresses({serializedAddresses: this.rawData})
            // .then(() => {
            //     this.isSuccess = true;
            //     this.isUpload = false;

            // })
            // .catch((error) =>{
            //     const event = new ShowToastEvent({
            //         title: 'Error',
            //         message: 'There was an error in the quote address creation. Please see the console for more details.',
            //         variant: 'Info'
            //     });
            //     this.dispatchEvent(event);
            //     console.error(error);
            // })

            //this.isUpload = false;

            const parsedData = JSON.parse(this.rawData);
            console.log('parsed data==>',parsedData);

            parsedData.forEach((record, index) => {
                // Check required fields
                if (!record.street || !record.city || !record.state) {
                    this.isFileNotValid = true; 
                    this.spinner=false;
                    const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
                return;
                }
            });

            const aAddressCount = parsedData.filter(record => record.a_address).length;
            const zAddressCount = parsedData.filter(record => record.z_address).length;

            if (aAddressCount !== zAddressCount) {
                console.error(
                    `Validation failed: Number of a_address records (${aAddressCount}) does not match number of z_address records (${zAddressCount}).`
                );
                this.isFileNotValid = true; // Mark as invalid
                this.spinner = false; // Stop the spinner
        
                // Dispatch navigation event
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
                return; // Exit as validation has failed
            }

            const zAddressSet = new Set(parsedData.map(record => record.z_address));

            // Validate mapping of a_address to z_address
            for (const record of parsedData) {
                if (record.a_address && !zAddressSet.has(record.a_address)) {
                    console.error(
                        `Validation failed: a_address '${record.a_address}' does not have a matching z_address in parsedData.`
                    );
                    this.isFileNotValid = true; // Mark as invalid
                    this.spinner = false; // Stop the spinner
        
                    // Dispatch navigation event
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                    return; // Exit as validation has failed
                }
            }



            
              if(!this.isFileNotValid){

                this.accordionData = []; // Clear existing data for a fresh start
                this.apiResponse = [];

                const searchPromises = parsedData.map((data, index) => {
                    const sectionKey = `accordion-${index + 1}`;
                    let a_address= data.a_address;
                    let z_address = data.z_address;
                    const accordionSection = {
                        key: sectionKey,
                        label: '',
                        options: [],
                        //options2 :[], // Placeholder for radio group options
                        selectedValue: ''
                         // Selected value for the radio group
                    };
        
                    return searchRecords({ search: data.street, preferred_states: data.state, preferred_cities: data.city })
                        .then((response) => {
                            console.log('new response==>'+response.parsedData);
                            if (response.apiResponse !== null) {
                                this.apiResponse.push(response.apiResponse);
                            }
                            const options = [];
                            const options2 = [];
                        
                            response.parsedData.forEach((item, i) => {
                                const option = {
                                    label: `${item.address}, ${item.city}, ${item.state},${item.country}, ${item.zipcode || ''}`.trim(),
                                    value:  `${item.address}, ${item.city}, ${item.state},${item.country}, ${item.zipcode},${a_address},${z_address}`.trim() // Unique value for each option
                                };
                        
                                // Alternate between options and options2 arrays
                                // if (i % 2 === 0) {
                                //     options.push(option); // Push to options array for even indices
                                // } else {
                                //     options2.push(option); // Push to options2 array for odd indices
                                // }
                                options.push(option);
                            });
                        
                            // Assign the arrays to the accordion section
                            accordionSection.options = options;
                           // accordionSection.options2 = options2;
                        
                            // Set the label from the first option of the first array (options)
                            accordionSection.label = options[0]?.label || 'No address found';
                            accordionSection.selectedValue = options[0]?.value ;
                            this.selectedValues[sectionKey] = options[0]?.value;
                        })
                        .catch((error) => {
                            console.error(`Error fetching results for ${data.street}:`, error);
                            accordionSection.options = [];
                        })
                        .finally(() => {
                            this.accordionData.push(accordionSection);
                            console.log('Accordion section',this.selectedValues);
                            
                        });
                });
        
                await Promise.all(searchPromises);
                console.log('Accordion Data:', this.accordionData);
                this.showAccordian = true; // Display accordion after all searches complete
        
                 console.log('apiResponse===>',this.apiResponse);
                 apiResponseInsert({apiResponses: this.apiResponse})
                 
                console.log('receivedAddresses',this.receivedAddresses);
                this.spinner = false;

              }
         
            
            //this.isUpload = false;    
            //this.showAccordian = true;        
        }
    }

    async parseCSV(file) {
        const text = await this.readFileAsText(file);
        this.rawData = this.csvToJSON(text);
    }

    readFileAsText(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = () => reject(reader.error);
            reader.readAsText(file);
        });
    }

    csvToJSON(csvText) {
        const lines = csvText.split('\n');
        const result = [];

        for (let i = 1; i < lines.length; i++) {
            const line = lines[i].trim();

            if (line === '') continue;

            const parts = line.split(',');

            // order will be 1) Opportunity Id, 2) Street, 3) City, 4) State, 5) Country, 6) Zip Code
            const street = parts[0];
            const city = parts[1];
            const state = parts[2];
            const zip = parts[3];
            const country = parts[4];
            const a_address = parts[5];
            const z_address = parts[6];
            result.push({ oppId: this.recordId, street, city, state, country, zip, a_address, z_address });
           // this.accordionData.push(street+' '+city+' '+state+' '+country+' '+zip);
        }
        console.log('result--->', result);
        console.log('accordionData--->', JSON.stringify(this.accordionData));
        
        return JSON.stringify(result);
    }

   
}