import { LightningElement, api, wire } from 'lwc';
import getAccountDetails from '@salesforce/apex/ACcountUIController.getAccountDetails';

export default class AccountUI extends LightningElement {
    @api recordId;
    accountData;
    logoUrl;
    error;

    @wire(getAccountDetails, { recordId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = data;
            this.logoUrl = data.image__c ? data.image__c : ''; 
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accountData = undefined;
            this.logoUrl = '';
            console.error('Error fetching Account data', error);
        }
    }

    get hasData() {
        return this.accountData !== undefined;
    }

    get formattedAddress() {
        if (!this.accountData) return 'N/A';

        const { BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry } = this.accountData;
        return [BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry]
            .filter(field => field) // Remove empty values
            .join(', ');
    }

    get computedCardClass() {
        return this.logoUrl ? 'card-container' : 'card-container no-logo';
    }
}