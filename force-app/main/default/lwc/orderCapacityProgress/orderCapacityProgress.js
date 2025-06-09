import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getOrderProgressData from '@salesforce/apex/OrderCapacityController.getOrderProgressData';
 
const FIELDS = ['Order.AccountId'];
 
export default class OrderCapacityDisplay extends LightningElement {
    @api recordId;
    accountId;
    orderData = {};
    error;
    dataLoaded = false;
 
    annualCapacityStyle = '';
    bookedOrdersStyle = '';
    invoiceOrdersStyle = '';
 
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    orderRecord({ error, data }) {
        if (data) {
            this.accountId = data.fields.AccountId.value;
            this.getOrderProgressData();
        } else if (error) {
            this.error = error.body?.message || error.message;
        }
    }
 
    getOrderProgressData() {
        if (this.accountId) {
            getOrderProgressData({ accountId: this.accountId })
                .then((data) => {
                    this.orderData = data;
                    console.log('orderData------>',this.orderData);
                    this.dataLoaded = true;
                    this.calculateProgressBars();
                })
                .catch((error) => {
                    this.error = error.body?.message || error.message;
                    this.dataLoaded = false;
                });
        }
    }
 
    calculateProgressBars() {
        const annual = this.orderData.AnnualCapacity || 1; // Avoid divide by 0
        console.log('annual ----->: ',annual);
        const booked = this.orderData.BookedOrders || 0;
        console.log('booked ----->: ',booked);
        const invoice = this.orderData.InvoiceOrders || 0;
        console.log('invoice ----->: ',invoice);
 
        this.annualCapacityStyle = `width: 100%; background-color: #003399;`;
        this.bookedOrdersStyle = `width: ${(booked / annual) * 100}%; background-color: #003399;`;
        this.invoiceOrdersStyle = `width: ${(invoice / annual) * 100}%; background-color: #003399;`;
    }
}