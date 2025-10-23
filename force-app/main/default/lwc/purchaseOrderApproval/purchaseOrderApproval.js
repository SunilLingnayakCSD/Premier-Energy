import { LightningElement, wire, track } from 'lwc';
import getOrdersForCurrentApprover from '@salesforce/apex/PurchaseOrderApprovalController.getOrdersForCurrentApprover';
import updateApprovalStatus from '@salesforce/apex/PurchaseOrderApprovalController.updateApprovalStatus';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
        label: 'Order Name',
        fieldName: 'OrderNameLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Account Name',
        fieldName: 'Account.Name',
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Type',
        fieldName: 'Type__c',
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Owner',
        fieldName: 'Owner.Name',
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'RSM Username',
        fieldName: 'RSM_Name__c',
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'RSM Role',
        fieldName: 'Rsm_Role__c',
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Total Amount',
        fieldName: 'Grand_Total__c',
        type: 'currency',
        typeAttributes: {
            currencyCode: 'INR',
            currencyDisplayAs: 'symbol'
        },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Approve',
        type: 'button',
        typeAttributes: {
            label: 'Approve',
            name: 'approve',
            variant: 'brand'
        }
    },
    {
        label: 'Reject',
        type: 'button',
        typeAttributes: {
            label: 'Reject',
            name: 'reject',
            variant: 'destructive'
        }
    }
];

export default class PurchaseOrderApproval extends LightningElement {
    @track orders = [];
    @track error;
    @track isRejectModalOpen = false;
    @track selectedOrderId;
    @track rejectionReason = '';
    columns = COLUMNS;
    wiredResult;

    get hasOrders() {
        return this.orders && this.orders.length > 0;
    }

    @wire(getOrdersForCurrentApprover)
    wiredOrders(result) {
        this.wiredResult = result;
        if (result.data) {
            this.orders = result.data.orders.map(order => {
                return {
                    ...order,
                    OrderNameLink: '/' + order.Id
                };
            });
            this.error = undefined;
        } else if (result.error) {
            console.error('Error loading orders:', result.error);
            this.error = result.error.body?.message || 'Error loading orders';
            this.orders = [];
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'approve') {
            this.approveOrder(row.Id);
        } else if (action.name === 'reject') {
            this.selectedOrderId = row.Id;
            this.isRejectModalOpen = true;
        }
    }

    approveOrder(orderId) {
        updateApprovalStatus({
            orderId: orderId,
            status: 'Approved',
            rejectionReason: null
        })
        .then(() => {
            this.showToast('Success', 'Order approved successfully', 'success');
            return refreshApex(this.wiredResult);
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to approve order', 'error');
        });
    }

    handleRejectionReasonChange(event) {
        this.rejectionReason = event.target.value;
    }

    confirmReject() {
        if (!this.rejectionReason.trim()) {
            this.showToast('Error', 'Please enter a rejection reason', 'error');
            return;
        }

        updateApprovalStatus({
            orderId: this.selectedOrderId,
            status: 'Rejected',
            rejectionReason: this.rejectionReason
        })
        .then(() => {
            this.showToast('Success', 'Order rejected successfully', 'success');
            this.closeRejectModal();
            return refreshApex(this.wiredResult);
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to reject order', 'error');
        });
    }

    closeRejectModal() {
        this.isRejectModalOpen = false;
        this.rejectionReason = '';
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(toastEvent);
    }
}