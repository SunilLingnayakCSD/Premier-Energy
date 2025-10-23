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

    connectedCallback() {
        const today = new Date();
        
        const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1); 
        console.log('lastMonthStart',lastMonthStart);
        
        
        const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0); 
        console.log('lastMonthEnd',lastMonthEnd);

        this.startDate = lastMonthStart.toISOString().split('T')[0]; 
        console.log('startDate',this.startDate);
        this.endDate = lastMonthEnd.toISOString().split('T')[0]; 
        console.log('enddate',this.enddate);

        this.fetchOrderCounts();
    }

    changeHandlerDate(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'startdate') {
            this.startDate = value;
        } else if (field === 'enddate') {
            this.enddate = value;
        }

        this.fetchOrderCounts();
    }

    fetchOrderCounts() {
        this.wiredOrders({ data: null, error: null });
    }

  
    @wire(orderMethod, { startdate: '$startDate', enddate: '$enddate' })
    wiredOrders({ data, error }) {
        if (data) {
            console.log('data', data);

    
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