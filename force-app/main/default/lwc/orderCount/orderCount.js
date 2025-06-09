// import { LightningElement, wire, track } from 'lwc';
// import orderMethod from '@salesforce/apex/orderCountApex.orderMethod';

// export default class OrderCount extends LightningElement {
//     @track startDate;
//     @track enddate;

//     @track orderCounts = {
//         total: 0,
//         closed: 0,
//         inprogress: 0,
//         intransit: 0,
//         cancelled: 0
//     };


//     connectedCallback() {
//         const today = new Date();
//         const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1); // First day of the last month
//         const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0); // Last day of the last month

//         // Format the dates to the correct format (yyyy-MM-dd) for input fields
//         this.date1 = lastMonthStart.toISOString().split('T')[0]; // Start of last month
//         this.date2 = lastMonthEnd.toISOString().split('T')[0]; // End of last month

//         // Fetch the lead counts for the last month by default
//         this.fetchOrderCounts();
//     }

     

//     // Handle date inputs
//     changeHandlerDate(event) {
//         const field = event.target.name;
//         const value = event.target.value;

//         if (field === 'startdate') {
//             this.startDate = value;
//         } else if (field === 'enddate') {
//             this.enddate = value;
//         }
//         this.fetchOrderCounts();
//     }

//     // Call the wire service to fetch the lead counts
//     fetchOrderCounts() {
//         // Trigger the wire method for the selected date range
//         this.wiredOrders({ data: null, error: null });
//     }

//     // Wire the Apex method
//     @wire(orderMethod, { startdate: '$startDate', enddate: '$enddate' })
//     wiredOrders({ data, error }) {
//         if (data) {
//             console.log('data',data);
            
//             this.orderCounts = {
//                 total: data.total || 0,
//                 closed: data.closed || 0,
//                 inprogress: data.inprogress || 0,
//                 intransit: data.intransit || 0,
//                 cancelled: data.cancelled || 0
//             };
//             console.log('orderCounts',this.orderCounts);
//         } else if (error) {
//             console.error('Error loading orders:', error);
//         }
//     }
// }


import { LightningElement, wire, track } from 'lwc';
import orderMethod from '@salesforce/apex/orderCountApex.orderMethod';

export default class OrderCount extends LightningElement {
    @track startDate;
    @track enddate;

    @track orderCounts = {
        total: 0,
        closed: 0,
        inprogress: 0,
        intransit: 0,
        cancelled: 0
    };

    // This function is triggered when the component is loaded
    connectedCallback() {
        // Get today's date
        const today = new Date();
        
        // Get the first day of the previous month
        const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1); // First day of last month
        console.log('lastMonthStart',lastMonthStart);
        
        
        // Get the last day of the previous month
        const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0); // Last day of last month
        console.log('lastMonthEnd',lastMonthEnd);

        // Format the dates in yyyy-MM-dd format to be used in input fields
        this.startDate = lastMonthStart.toISOString().split('T')[0]; // Start of last month
        console.log('startDate',this.startDate);
        this.endDate = lastMonthEnd.toISOString().split('T')[0]; // End of last month
        console.log('enddate',this.enddate);

        // Fetch the order counts for the last month by default
        this.fetchOrderCounts();
    }

    // Handle date input changes from the user
    changeHandlerDate(event) {
        const field = event.target.name;
        const value = event.target.value;

        // Update the respective date fields
        if (field === 'startdate') {
            this.startDate = value;
        } else if (field === 'enddate') {
            this.enddate = value;
        }

        // Fetch the order counts based on the selected dates
        this.fetchOrderCounts();
    }

    // Fetch order counts from the Apex method
    fetchOrderCounts() {
        // This triggers the wire service and fetches the counts for the selected date range
        this.wiredOrders({ data: null, error: null });
    }

    // Wire the Apex method to get the order counts
    @wire(orderMethod, { startdate: '$startDate', enddate: '$enddate' })
    wiredOrders({ data, error }) {
        if (data) {
            console.log('data', data);

            // Map the data to the order counts
            this.orderCounts = {
                total: data.total || 0,
                closed: data.closed || 0,
                inprogress: data.inprogress || 0,
                intransit: data.intransit || 0,
                cancelled: data.cancelled || 0
            };

            console.log('orderCounts', this.orderCounts);
        } else if (error) {
            console.error('Error loading orders:', error);
        }
    }
}