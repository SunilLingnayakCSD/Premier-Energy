import { LightningElement, wire, track } from 'lwc';
import getOrders from '@salesforce/apex/PurchaseOrderController.getOrders';
import getPicklistValues from '@salesforce/apex/PurchaseOrderController.getPicklistValues';

const COLUMNS = [
    { label: 'Id', fieldName: 'Id', type: 'text' },
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Type', fieldName: 'Type__c', type: 'text' },
    { label: 'Region', fieldName: 'Region__c', type: 'text' },

];

export default class OrderFilter extends LightningElement {
    @track orders = [];
    @track error;
    @track selectedType = '';
    @track selectedRegion = '';
    @track typeOptions = [];
    @track regionOptions = [];
    columns = COLUMNS;

    @wire(getPicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            // Format Type options
            this.typeOptions = data.type.map(value => ({
                label: value,
                value: value
            }));

            // Format Region options
            this.regionOptions = data.region.map(value => ({
                label: value,
                value: value
            }));
        } else if (error) {
            this.error = error.body.message;
        }
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
    }

    handleFilter() {
        getOrders({
            type: this.selectedType,
            region: this.selectedRegion
        })
        .then(result => {
            this.orders = result;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error.body.message;
            this.orders = [];
        });
    }
}