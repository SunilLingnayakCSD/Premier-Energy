// import { LightningElement, wire } from 'lwc';
// import LeadMethod from '@salesforce/apex/LeadCountApex.LeadMethod';

// export default class LeadCount extends LightningElement {
//     leadCounts = {
//         total: 0,
//         completed: 0,
//         pending: 0,
//         rejected: 0
//     };
//     date1;
//     date2;

//     handleDateChange(event) {
//         const fieldName = event.target.name;
//         const value = event.target.value;
//         if (fieldName === 'startDate') {
//             this.date1 = value;
//         } else if (fieldName === 'endDate') {
//             this.date2 = value;
//         }
//     }


//     @wire(LeadMethod,{ startDate:'$date1',endDate:'$date2'})
//     wiredLeads({ data, error }) {
//         if (data) {
//             this.leadCounts = {
//                 total: data.total || 0,
//                 completed: data['Purchased Module'] || 0,
//                 pending: data['New'] || 0,
//                 rejected: data['Rejected'] || 0
//             };
//         } else if (error) {
//             console.error('Error fetching leads:', error);
//         }
//     }
// }




// import { LightningElement, wire, track } from 'lwc';
// import LeadMethod from '@salesforce/apex/LeadCountApex.LeadMethod';

// export default class LeadCount extends LightningElement {
//     @track leadCounts = {
//         total: 0,
//         open: 0,
//         rejected: 0,
//         converted: 0,
//         closed: 0
//     };

//     date1;
//     date2;

//     handleDateChange(event) {
//         const field = event.target.name;
//         const value = event.target.value;

//         if (field === 'startDate') {
//             this.date1 = value;
//         } else if (field === 'endDate') {
//             this.date2 = value;
//         }
//     }

//     @wire(LeadMethod, { startDate: '$date1', endDate: '$date2' })
//     wiredLeads({ data, error }) {
//         if (data) {
//             console.log('data',data);
            
//             this.leadCounts = {
//                 total: data.total || 0,
//                 open: data.open || 0,
//                 rejected: data.rejected || 0,
//                 converted: data.converted || 0,
//                 closed: data.closed || 0
//             };
//             console.log('leadcounts',this.leadCounts);
            
//         } else if (error) {
//             console.error('Error fetching lead counts:', error);
//         }
//     }
// }
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

    // Calculate the start and end dates for the last month
    connectedCallback() {
        const today = new Date();
        const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1); // First day of the last month
        const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0); // Last day of the last month

        // Format the dates to the correct format (yyyy-MM-dd) for input fields
        this.date1 = lastMonthStart.toISOString().split('T')[0]; // Start of last month
        this.date2 = lastMonthEnd.toISOString().split('T')[0]; // End of last month

        // Fetch the lead counts for the last month by default
        this.fetchLeadCounts();
    }

    // Handle date change events from input fields
    handleDateChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'startDate') {
            this.date1 = value;
        } else if (field === 'endDate') {
            this.date2 = value;
        }

        // Fetch the lead counts based on the selected dates
        this.fetchLeadCounts();
    }

    // Call the wire service to fetch the lead counts
    fetchLeadCounts() {
        // Trigger the wire method for the selected date range
        this.wiredLeads({ data: null, error: null });
    }

    // Fetch lead counts based on start and end dates
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