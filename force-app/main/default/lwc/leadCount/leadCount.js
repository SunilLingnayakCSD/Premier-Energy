import { LightningElement, wire, track } from 'lwc';
import LeadMethod from '@salesforce/apex/LeadCountApex.LeadMethod';

export default class LeadCount extends LightningElement {
    @track leadCounts = {
        total: 0,
        open: 0,
        rejected: 0,
        converted: 0,
        closed: 0
    };

    date1;
    date2;

    connectedCallback() {
        const today = new Date();
        const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1);
        const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0);

        this.date1 = lastMonthStart.toISOString().split('T')[0];
        this.date2 = lastMonthEnd.toISOString().split('T')[0];

        this.fetchLeadCounts();
    }

    handleDateChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'startDate') {
            this.date1 = value;
        } else if (field === 'endDate') {
            this.date2 = value;
        }

        this.fetchLeadCounts();
    }

    fetchLeadCounts() {
        this.wiredLeads({ data: null, error: null });
    }

    @wire(LeadMethod, { startDate: '$date1', endDate: '$date2' })
    wiredLeads({ data, error }) {
        if (data) {
            console.log('data', data);

            this.leadCounts = {
                total: data.total || 0,
                open: data.open || 0,
                rejected: data.rejected || 0,
                converted: data.converted || 0,
                closed: data.closed || 0
            };
            console.log('leadcounts', this.leadCounts);
        } else if (error) {
            console.error('Error fetching lead counts:', error);
        }
    }
}