import { LightningElement, api, wire } from 'lwc';
import getContactDetails from '@salesforce/apex/ContactUIController.getContactDetails';

export default class ContactUI extends LightningElement {
    @api recordId;
    contactData;
    error;
    profileCompleteness = 0;
    progressClass = '';
    imageUrl; 
    formattedAddress = ''; // Stores formatted address

    @wire(getContactDetails, { recordId: '$recordId' })
    wiredContact({ error, data }) {
        if (data) {
            this.contactData = data;
            this.error = undefined;

            // Set image URL if image__c exists
            this.imageUrl = data.Image__c && data.Image__c.trim() !== '' ? data.Image__c : null;
            
            // Remove empty values & join with commas dynamically
            this.formattedAddress = [
                data.MailingStreet,
                data.MailingCity,
                data.MailingState,
                data.MailingPostalCode,
                data.MailingCountry
            ].filter(value => value && value.trim() !== '').join(', ') || 'N/A'; // Default to 'N/A' if empty

            this.calculateProfileCompleteness();
        } else if (error) {
            this.error = error;
            this.contactData = undefined;
            console.error('Error fetching Contact data', error);
        }
    }

    calculateProfileCompleteness() {
        if (!this.contactData) return;

        const requiredFields = ['Name', 'Image__c', 'Phone', 'Email', 'MailingStreet', 'Customer_Since__c'];
        let filledFields = requiredFields.filter(field => this.contactData[field]);
        let completeness = Math.round((filledFields.length / requiredFields.length) * 100);

        this.profileCompleteness = completeness;

        if (completeness < 50) {
            this.progressClass = 'low';
        } else if (completeness < 80) {
            this.progressClass = 'medium';
        } else {
            this.progressClass = 'high';
        }
    }

    get profileCompletenessStyle() {
        return `width: ${this.profileCompleteness}%`;
    }

    get hasData() {
        return this.contactData !== undefined;
    }

    get showImage() {
        return !!this.imageUrl;
    }
}