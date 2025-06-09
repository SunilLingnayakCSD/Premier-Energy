import { LightningElement, track } from 'lwc';
import getInvoiceCounts from '@salesforce/apex/InvoiceCount.getInvoiceCounts'; 

export default class InvoiceCount extends LightningElement {
    @track date1; 
    @track date2;
    @track totalInvoices = 0;
    @track totalPODInvoices = 0;
    @track totalFTRInvoices = 0;

    connectedCallback() {
        this.setDefaultDates();
        this.fetchCounts();
    }

    setDefaultDates() {
        const today = new Date();
        const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDayOfPrevMonth = new Date(firstDayOfMonth.setDate(0));
        const firstDayOfPrevMonth = new Date(lastDayOfPrevMonth.getFullYear(), lastDayOfPrevMonth.getMonth(), 1);
        
        this.date1 = firstDayOfPrevMonth.toISOString().split('T')[0];
        this.date2 = lastDayOfPrevMonth.toISOString().split('T')[0];
    }

    handleDateChange(event) {
        this[event.target.name] = event.target.value;
        this.fetchCounts();
    }

    fetchCounts() {
        getInvoiceCounts({
            startDate: this.date1, 
            endDate: this.date2
        }).then(result => {
            this.totalInvoices = result.totalInvoices || 0;
            this.totalPODInvoices = result.totalPODInvoices || 0;
            this.totalFTRInvoices = result.totalFTRInvoices || 0;
        }).catch(error => {
            console.error('Error:', error.body.message);
        });
    }
}