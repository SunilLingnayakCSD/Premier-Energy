// import { LightningElement, wire, track } from 'lwc';
// import getInternationalLeads from '@salesforce/apex/LeadApprovalInternationalController.getInternationalLeads';
// import updateLeadStatus from '@salesforce/apex/LeadApprovalInternationalController.updateLeadStatus';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { refreshApex } from '@salesforce/apex';

// export default class LeadApprovalInternational extends LightningElement {
//     @track leads = [];
//     @track columns = [];
//     @track isRejectModalOpen = false;
//     @track isOnHoldModalOpen = false;
//     @track rejectionReason = '';
//     @track selectedRejectionReason = '';
//     @track showOtherReasonField = false;
//     @track onHoldReason = '';

//     selectedLeadId;

//     rejectionReasons = [
//         { label: "Customer’s Bankrupt / Blocklisted profile", value: "Customer’s Bankrupt / Blocklisted profile" },
//         { label: "Unable to meet the delivery requirement", value: "Unable to meet the delivery requirement" },
//         { label: "Unable to meet the Product and Technology requirements", value: "Unable to meet the Product and Technology requirements" },
//         { label: "Geographical and Execution limitations / restrictions", value: "Geographical and Execution limitations / restrictions" },
//         { label: "Others", value: "Others" }
//     ];

//     wiredLeadsResult;

//     columns = [
//         {
//             label: 'Lead Name',
//             fieldName: 'leadLink',
//             type: 'url',
//             typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
//         },
//         { label: 'Company', fieldName: 'Company' },
//         { label: 'Country', fieldName: 'Country' },
//         { label: 'Status', fieldName: 'Status' },
//         {
//             label: 'Approve',
//             type: 'button',
//             typeAttributes: { label: 'Approve', name: 'approve', variant: 'brand' }
//         },
//         {
//             label: 'Reject',
//             type: 'button',
//             typeAttributes: { label: 'Reject', name: 'reject', variant: 'destructive' }
//         },
//         {
//             label: 'On Hold',
//             type: 'button',
//             typeAttributes: { label: 'On Hold', name: 'onhold', variant: 'neutral' }
//         }
//     ];

//     @wire(getInternationalLeads)
//     wiredLeads(result) {
//         this.wiredLeadsResult = result;
//         if (result.data) {
//             this.leads = result.data.leads.map(lead => {
//                 return {
//                     ...lead,
//                     leadLink: `/lightning/r/Lead/${lead.Id}/view`
//                 };
//             });
//         } else if (result.error) {
//             this.leads = [];
//             this.showToast('Error', 'Error loading leads', 'error');
//         }
//     }

//     handleRowAction(event) {
//         const actionName = event.detail.action.name;
//         const row = event.detail.row;
//         this.selectedLeadId = row.Id;

//         if (actionName === 'approve') {
//             this.handleUpdateStatus('Approved');
//         } else if (actionName === 'reject') {
//             this.isRejectModalOpen = true;
//             this.selectedRejectionReason = '';
//             this.rejectionReason = '';
//             this.showOtherReasonField = false;
//         } else if (actionName === 'onhold') {
//             this.isOnHoldModalOpen = true;
//             this.onHoldReason = '';
//         }
//     }

//     handleUpdateStatus(status, reason = '', otherReason = '') {
//         updateLeadStatus({ leadId: this.selectedLeadId, status, reason, otherReason })
//             .then(() => {
//                 this.showToast('Success', `Lead ${status}`, 'success');
//                 this.isRejectModalOpen = false;
//                 this.isOnHoldModalOpen = false;
//                 return refreshApex(this.wiredLeadsResult);
//             })
//             .catch(error => {
//                 this.showToast('Error', error.body.message, 'error');
//             });
//     }

//     handleRejectReasonChange(event) {
//         this.selectedRejectionReason = event.detail.value;
//         this.showOtherReasonField = (this.selectedRejectionReason === 'Others');
//         if (!this.showOtherReasonField) {
//             this.rejectionReason = '';
//         }
//     }

//     handleRejectReasonInput(event) {
//         this.rejectionReason = event.target.value;
//     }

//     confirmReject() {
//         if (!this.selectedRejectionReason) {
//             this.showToast('Error', 'Please select a rejection reason', 'error');
//             return;
//         }
//         if (this.selectedRejectionReason === 'Others' && !this.rejectionReason.trim()) {
//             this.showToast('Error', 'Please enter other rejection reason', 'error');
//             return;
//         }
//         this.handleUpdateStatus('Rejected', this.selectedRejectionReason, this.rejectionReason);
//     }

//     handleOnHoldReasonInput(event) {
//         this.onHoldReason = event.target.value;
//     }

//     confirmOnHold() {
//         if (!this.onHoldReason.trim()) {
//             this.showToast('Error', 'Please enter reason for On Hold', 'error');
//             return;
//         }
//         this.handleUpdateStatus('On Hold', this.onHoldReason);
//     }

//     closeRejectModal() {
//         this.isRejectModalOpen = false;
//         this.selectedRejectionReason = '';
//         this.rejectionReason = '';
//         this.showOtherReasonField = false;
//     }

//     closeOnHoldModal() {
//         this.isOnHoldModalOpen = false;
//         this.onHoldReason = '';
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }
// }





import { LightningElement, wire, track } from 'lwc';
import getInternationalLeads from '@salesforce/apex/LeadApprovalInternationalController.getInternationalLeads';
import updateLeadStatus from '@salesforce/apex/LeadApprovalInternationalController.updateLeadStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LeadApprovalInternational extends LightningElement {
    @track leads = [];
    @track columns = [];
    @track isRejectModalOpen = false;
    @track isOnHoldModalOpen = false;
    @track rejectionReason = '';
    @track selectedRejectionReason = '';
    @track showOtherReasonField = false;
    @track onHoldReason = '';

    selectedLeadId;

    rejectionReasons = [
        { label: "Customer’s Bankrupt / Blocklisted profile", value: "Customer’s Bankrupt / Blocklisted profile" },
        { label: "Unable to meet the delivery requirement", value: "Unable to meet the delivery requirement" },
        { label: "Unable to meet the Product and Technology requirements", value: "Unable to meet the Product and Technology requirements" },
        { label: "Geographical and Execution limitations / restrictions", value: "Geographical and Execution limitations / restrictions" },
        { label: "Others", value: "Others" }
    ];

    wiredLeadsResult;

    columns = [
        {
            label: 'Lead Name',
            fieldName: 'leadLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Company', fieldName: 'Company' },
        { label: 'Country', fieldName: 'Country' },
        { label: 'Status', fieldName: 'Status' },
        {
            label: 'Approve',
            type: 'button',
            typeAttributes: { label: 'Approve', name: 'approve', variant: 'brand' }
        },
        {
            label: 'Reject',
            type: 'button',
            typeAttributes: { label: 'Reject', name: 'reject', variant: 'destructive' }
        },
        {
            label: 'On Hold',
            type: 'button',
            typeAttributes: { label: 'On Hold', name: 'onhold', variant: 'neutral' }
        }
    ];

    @wire(getInternationalLeads)
    wiredLeads(result) {
        this.wiredLeadsResult = result;
        if (result.data) {
            console.log('Leads fetched:', result.data.leads);
            this.leads = result.data.leads.map(lead => {
                return {
                    ...lead,
                    leadLink: `/lightning/r/Lead/${lead.Id}/view`
                };
            });
        } else if (result.error) {
            console.error('Error loading leads:', result.error);
            this.leads = [];
            this.showToast('Error', 'Error loading leads', 'error');
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.selectedLeadId = row.Id;

        console.log(`Action: ${actionName} on Lead Id: ${this.selectedLeadId}`);

        if (actionName === 'approve') {
            this.handleUpdateStatus('Approved');
        } else if (actionName === 'reject') {
            this.isRejectModalOpen = true;
            this.selectedRejectionReason = '';
            this.rejectionReason = '';
            this.showOtherReasonField = false;
            console.log('Reject modal opened');
        } else if (actionName === 'onhold') {
            this.isOnHoldModalOpen = true;
            this.onHoldReason = '';
            console.log('On Hold modal opened');
        }
    }

    handleUpdateStatus(status, reason = '', otherReason = '') {
        console.log(`Updating lead ${this.selectedLeadId} status to ${status}, reason: ${reason}, otherReason: ${otherReason}`);

        updateLeadStatus({ leadId: this.selectedLeadId, status, reason, otherReason })
            .then(() => {
                console.log(`Lead ${this.selectedLeadId} updated successfully to status ${status}`);
                this.showToast('Success', `Lead ${status}`, 'success');
                this.isRejectModalOpen = false;
                this.isOnHoldModalOpen = false;
                return refreshApex(this.wiredLeadsResult);
            })
            .catch(error => {
                console.error('Error updating lead status:', error);
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleRejectReasonChange(event) {
        this.selectedRejectionReason = event.detail.value;
        this.showOtherReasonField = (this.selectedRejectionReason === 'Others');
        console.log('Selected rejection reason:', this.selectedRejectionReason);
        if (!this.showOtherReasonField) {
            this.rejectionReason = '';
        }
    }

    handleRejectReasonInput(event) {
        this.rejectionReason = event.target.value;
        console.log('Other rejection reason input:', this.rejectionReason);
    }

    confirmReject() {
        console.log('Confirm reject clicked');
        if (!this.selectedRejectionReason) {
            this.showToast('Error', 'Please select a rejection reason', 'error');
            return;
        }
        if (this.selectedRejectionReason === 'Others' && !this.rejectionReason.trim()) {
            this.showToast('Error', 'Please enter other rejection reason', 'error');
            return;
        }
        this.handleUpdateStatus('Rejected', this.selectedRejectionReason, this.rejectionReason);
    }

    handleOnHoldReasonInput(event) {
        this.onHoldReason = event.target.value;
        console.log('On Hold reason input:', this.onHoldReason);
    }

    confirmOnHold() {
        console.log('Confirm on hold clicked');
        if (!this.onHoldReason.trim()) {
            this.showToast('Error', 'Please enter reason for On Hold', 'error');
            return;
        }
        this.handleUpdateStatus('On Hold', this.onHoldReason);
    }

    closeRejectModal() {
        this.isRejectModalOpen = false;
        this.selectedRejectionReason = '';
        this.rejectionReason = '';
        this.showOtherReasonField = false;
        console.log('Reject modal closed');
    }

    closeOnHoldModal() {
        this.isOnHoldModalOpen = false;
        this.onHoldReason = '';
        console.log('On Hold modal closed');
    }

    showToast(title, message, variant) {
        console.log(`Toast: [${variant}] ${title} - ${message}`);
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}