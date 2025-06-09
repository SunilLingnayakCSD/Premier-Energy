import { LightningElement, wire, track } from 'lwc';
import getPurchaseOrders from '@salesforce/apex/PurchaseOrderController.getPurchaseOrders';
import updateApprovalStatus from '@salesforce/apex/PurchaseOrderController.updateApprovalStatus';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Order Number', fieldName: 'OrderNumber', type: 'text' },
    { 
        label: 'Account Name', 
        fieldName: 'AccountName', 
        type: 'text',
        cellAttributes: { class: { fieldName: 'accountClass' } }
    },
    { 
        label: 'Total Capacity (MWp)', 
        fieldName: 'Total_Capacity_in_MWp__c', 
        type: 'number',
        cellAttributes: { alignment: 'left' }
    },
    { 
        label: 'Order Amount', 
        fieldName: 'TotalAmount', 
        type: 'currency', 
        typeAttributes: { 
            currencyCode: 'USD',
            currencyDisplayAs: 'symbol'
        },
        cellAttributes: { alignment: 'left' }
    },
    { 
        label: 'Product Type', 
        fieldName: 'Product_Type__c', 
        type: 'text',
        cellAttributes: { iconName: { fieldName: 'productIcon' } }
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Approve', name: 'approve', iconName: 'utility:check' },
                { label: 'Reject', name: 'reject', iconName: 'utility:clear' }
            ],
            menuAlignment: 'right'
        }
    }
];

export default class PurchaseOrderApproval extends LightningElement {
    @track orders = [];
    @track error;
    columns = COLUMNS;
    wiredResult;

    @wire(getPurchaseOrders)
    wiredOrders(result) {
        this.wiredResult = result;
        if (result.data) {
            this.orders = result.data.orders.map(order => ({
                ...order,
                AccountName: order.Account?.Name || 'N/A',
                accountClass: order.Approval_Status__c === 'Approved' ? 'slds-text-color_success' : 
                             order.Approval_Status__c === 'Rejected' ? 'slds-text-color_error' : '',
                productIcon: this.getProductIcon(order.Product_Type__c)
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Error loading purchase orders';
            this.orders = [];
            console.error('Error loading data:', result.error);
        }
    }

    getProductIcon(productType) {
        switch(productType) {
            case 'Modules': return 'standard:product';
            case 'Water Pump': return 'standard:product_required';
            case 'EPC': return 'standard:maintenance_plan';
            default: return 'standard:orders';
        }
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        const status = action === 'approve' ? 'Approved' : 'Rejected';
        
        updateApprovalStatus({ orderId: row.Id, status })
            .then(() => {
                this.showToast('Success', `Order ${row.OrderNumber} has been ${status}`, 'success');
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to update status', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}