/**
 * @author Ladd Partners
 * @date 4/30/2025
 */

import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createITSPayableInvoiceline from '@salesforce/apex/lp_BillingContractLineSearchController.createITSPayableInvoiceline';
import getVendorFromInvoice from '@salesforce/apex/lp_BillingContractLineSearchController.getVendorFromInvoice';
import searchContractLineItems from '@salesforce/apex/lp_BillingContractLineSearchController.searchContractLineItems';

const ERROR_JS_UNKNOWN = 'Unknown Javascript Error in method: ';
const COLUMN_CURRENCY = {
    type: 'currency',
    hideDefaultActions: true,
    typeAttributes: { currencyCode: 'USD' },
};
const COLUMN_DATE = {
	type: 'date',
	hideDefaultActions: true,
	cellAttributes: { alignment: 'center' },
};
const COLUMN_TEXT = {
	type: 'text',
	hideDefaultActions: true,
	cellAttributes: { alignment: 'center' },
};

export default class lp_BillingContractLineSearch extends NavigationMixin(LightningElement) {
	@api recordId;
	loading = false;
	contractLineColumns = [
		{ ...COLUMN_TEXT, label: 'Contract Line', fieldName: 'name' },
		{ ...COLUMN_TEXT, label: 'LEC Circuit', fieldName: 'lecCircuitName' },
		{ ...COLUMN_TEXT, label: 'USS Circuit', fieldName: 'ussCircuitName' },
		{ ...COLUMN_TEXT, label: 'LEC Term', fieldName: 'lecCircuitTerm' },
		{ ...COLUMN_TEXT, label: 'Ordered Type', fieldName: 'orderedType' },
		{ ...COLUMN_DATE, label: 'LEC Start Date', fieldName: 'lecStartDate' },
		{ ...COLUMN_DATE, label: 'LEC Due Date', fieldName: 'lecDueDate' },
		{ ...COLUMN_TEXT, label: 'LEC Order Number', fieldName: 'lecOrderNumber' },
		{ ...COLUMN_TEXT, label: 'LEC Vendor', fieldName: 'lecVendorName' },
		{ ...COLUMN_TEXT, label: 'Billing Type', fieldName: 'billingType' },
		{ ...COLUMN_CURRENCY, label: 'Amount', fieldName: 'amount' },
	];
	contractLineId = null;
	@track contractLines = [];
	forceModalWidth = false;
	searchByLEC = true;
	searchTerm = '';
	selectedLine = [];
	@track vendorId = null;
	matchVendor = true;

	connectedCallback() {
		console.log('recordId: ' + JSON.stringify(this.recordId));
		this.getVendorFromInvoice();
	}

	renderedCallback() {
		if (!this.forceModalWidth) return;
		const styleElement = document.createElement('style');
		styleElement.innerText = `.uiModal--medium .modal-container {
			width: 90vw;
			max-width: 90vw;
			height: 90vh;
			max-height: 90vh;
		}`;
		this.template.querySelector('lightning-card').appendChild(styleElement);
		this.forceModalWidth = false;
	}

	createLine() {
		if (this.isNullOrBlank(this.contractLineId)) {
			this.showToast('Warning', 'You must select 1 contract line to continue.', 'warning');
			return;
		}
		this.loading = true;
		let newLineId = null;
		createITSPayableInvoiceline({ lineFromLwc: this.selectedLine })
			.then((result) => {
				if (result.error) {
					console.log('createLine Apex Error');
					this.showToast('Error', result.message, 'error', 'sticky');
					return;
				}
				newLineId = result.message;
			})
			.catch((error) => {
				console.log('createLine Error: ' + JSON.stringify(error));
				const errorMsg = error.body ? error.body.message : ERROR_JS_UNKNOWN + 'createLine';
				this.showToast('Error', errorMsg, 'error', 'sticky');
			})
			.finally(() => {
				this.loading = false;
				if (!this.isNullOrBlank(newLineId)) {
					this.navigateToNewLine(newLineId);
					this.dispatchEvent(new CloseActionScreenEvent());
				}
			});
	}

	focusSearchField(DELAY) {
		const inputField = this.template.querySelector('[data-id="searchInput"]');
		if (inputField) {
			setTimeout(() => {
				inputField.focus();
			}, DELAY ?? 1000);
		}
	}

	getVendorFromInvoice() {
		this.loading = true;
		setTimeout(() => {
			console.log('recordId: ' + JSON.stringify(this.recordId));
			getVendorFromInvoice({ itsInvoiceId: this.recordId })
				.then((result) => {
					if (result.error) {
						console.log('getVendorFromInvoice Apex Error');
						this.showToast('Error', result.message, 'error', 'sticky');
						return;
					}
					this.vendorId = result.vendorId;
				})
				.catch((error) => {
					console.log('getVendorFromInvoice Error: ' + JSON.stringify(error));
					const errorMsg = error.body ? error.body.message : ERROR_JS_UNKNOWN + 'getVendorFromInvoice';
					this.showToast('Error', errorMsg, 'error', 'sticky');
				})
				.finally(() => {
					this.loading = false;
					this.focusSearchField(1500);
				});
		}, 500);
	}

	handleCircuitSwitch() {
		this.searchByLEC = !this.searchByLEC;
	}

	handleRowSelection(event) {
		this.contractLineId = event.detail.selectedRows[0].id;
		this.selectedLine = { ...event.detail.selectedRows[0] };
		this.selectedLine['invoiceId'] = this.recordId;
	}

	handleSearch() {
		if (this.isNullOrBlank(this.searchTerm)) return;
		this.loading = true;
		searchContractLineItems({
			searchTerm: this.searchTerm,
			useLecCircuitId: this.searchByLEC,
			vendorId: this.matchVendor ? this.vendorId : null,
		})
			.then((result) => {
				if (result.error) {
					console.log('searchContractLineItems Apex Error');
					this.showToast('Error', result.message, 'error', 'sticky');
					return;
				}
				if (result.warning) {
					console.log('searchContractLineItems Apex Warning');
					this.showToast('Warning', result.message, 'warning');
					return;
				}
				this.contractLines = [...result.contractLines];
				this.forceModalWidth = true;
				console.log('contractLines: ' + JSON.stringify(this.contractLines));
			})
			.catch((error) => {
				console.log('searchContractLineItems Error: ' + JSON.stringify(error));
				const errorMsg = error.body ? error.body.message : ERROR_JS_UNKNOWN + 'searchContractLineItems';
				this.showToast('Error', errorMsg, 'error', 'sticky');
			})
			.finally(() => {
				this.loading = false;
			});
	}

	handleSearchTermChange(event) {
		this.searchTerm = event.target.value;
	}

	handleVendorToggle(event) {
		this.matchVendor = event.target.checked;
	}

	navigateToNewLine(lineId) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: lineId,
				objectApiName: 'Master_ITS_Payable_Invoice_Line__c',
				actionName: 'view',
			},
		});
	}

	resetForm() {
		this.searchTerm = null;
		this.contractLines.length = 0;
		setTimeout(() => {
			this.focusSearchField();
		}, 500);
	}

	isNullOrBlank(s) {
		return s === undefined || s === null || s === '';
	}

	showToast(t, msg, v, m) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: t || 'Unknown Error',
				message: msg,
				variant: v || 'error',
				mode: m || 'dismissible',
			})
		);
	}
}