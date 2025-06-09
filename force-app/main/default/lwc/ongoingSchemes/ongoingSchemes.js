import { LightningElement,track,wire } from 'lwc';
import UserSpecificPromos from '@salesforce/apex/getUserSpecificPromos.UserSpecificPromos';

export default class OngoingSchemes extends LightningElement {
    @track promos = [];
    @track error;

    @wire(UserSpecificPromos)
    wiredPromos({ error, data }) {
        if (data) {
            this.promos = data;
            this.error = undefined;
            console.log('Fetched promos:', data);
        } else if (error) {
            this.error = error;
            console.error('Error fetching promos:', error);
        }
    }
}