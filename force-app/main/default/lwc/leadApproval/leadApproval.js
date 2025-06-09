import { LightningElement, wire, track } from 'lwc';
import getLeads from '@salesforce/apex/LeadApprovalController.getLeads';
import updateLeadStatus from '@salesforce/apex/LeadApprovalController.updateLeadStatus';
import updateMDApproval from '@salesforce/apex/LeadApprovalController.updateMDApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LeadApproval extends LightningElement {
    @track leads = [];
    @track isRejectModalOpen = false;
    @track rejectionReason = '';
    @track selectedRejectionReason = ''; // Picklist value
    @track showOtherReasonField = false; // Controls Other Reason input
    selectedLeadId;
    selectedLeadProjectType;
    selectedLeadMDApproved;
    wiredLeadResult;

    rejectionReasons = [
        { label: "Customer’s Bankrupt / Blocklisted profile", value: "Customer's Bankrupt / Blocklisted profile" },
        { label: "Unable to meet the delivery requirement", value: "Unable to meet the delivery requirement" },
        { label: "Unable to meet the Product and Technology requirements", value: "Unable to meet the Product and Technology requirements" },
        { label: "Geographical and Execution limitations / restrictions", value: "Geographical and Execution limitations / restrictions" },
        { label: "Others", value: "Others" }
    ];

    baseColumns = [
        { 
            label: 'LEAD ID', 
            fieldName: 'leadIdLink',  // Link to lead record
            type: 'url',
            typeAttributes: { 
                label: { fieldName: 'Lead_ID__c' },  // Display the Lead ID as a label
                target: '_blank' 
            } 
        },
        {  
            label: 'LEAD NAME', 
            fieldName: 'Name'
        },
        { 
            label: 'APPROVE', 
            type: 'button', 
            typeAttributes: {  
                label: 'Approve', name: 'approve', variant: 'brand' 
            }
        },
        { 
            label: 'REJECT', 
            type: 'button', 
            typeAttributes: { 
                label: 'Reject', name: 'reject', variant: 'destructive' 
            } 
        },
        { 
            label: 'ON HOLD', 
            type: 'button', 
            typeAttributes: { 
                label: 'On Hold', name: 'onhold', variant: 'neutral' 
            } 
        }
    ];

    additionalColumns = [
        { label: 'COMPANY', fieldName: 'Company' },
        { label: 'EMAIL ID', fieldName: 'Email', type: 'email' },
        { label: 'PHONE NO', fieldName: 'Phone', type: 'phone' }
    ];

    GovtColumns = [
        { label: 'COUNTRY', fieldName: 'Country' },
        { label: 'STATE', fieldName: 'State' },
        { label: 'SCHEMA NAME', fieldName: 'Scheme_Name__c' }
    ];

    @wire(getLeads)
    wiredLeads(result) {
        this.wiredLeadResult = result;
        const { error, data } = result;

        if (data) {
            console.log('Lead Data:', JSON.stringify(data));
            this.leads = data.leads && data.leads.length > 0 ? data.leads.map(lead => ({
                ...lead,
                leadIdLink: `/lightning/r/Lead/${lead.Id}/view`
            })) : [];

            // Start with baseColumns (excluding 'ON HOLD' initially)
            let baseColumnsWithoutOnHold = this.baseColumns.filter(col => col.typeAttributes?.label !== 'On Hold');

            // Check if any lead has the status 'Tender Participation Request'
            const hasTenderParticipationRequest = this.leads.some(lead => lead.Status === 'Tender Participation Request');

            // If any lead has status 'Tender Participation Request', exclude the 'On Hold' button
            if (hasTenderParticipationRequest) {
                // Remove the 'On Hold' button for all leads
                baseColumnsWithoutOnHold = baseColumnsWithoutOnHold.filter(col => col.typeAttributes?.label !== 'On Hold');
            } else {
                // If there is no "Tender Participation Request" status, keep the "On Hold" button
                const onHoldColumn = this.baseColumns.find(col => col.typeAttributes?.label === 'On Hold');
                if (onHoldColumn) {
                    baseColumnsWithoutOnHold.push(onHoldColumn);
                }
            }

            // Find the index of the 'Lead Name' column to insert additional columns after it
            const leadNameIndex = baseColumnsWithoutOnHold.findIndex(col => col.fieldName === 'Name');

            // Insert additionalColumns after the Lead Name column
            if (leadNameIndex !== -1) {
                baseColumnsWithoutOnHold.splice(leadNameIndex + 1, 0, ...this.additionalColumns);
            }

            // Set final columns
            this.columns = [...baseColumnsWithoutOnHold];
        } else if (error) {
            console.error('Error fetching leads:', error);
            this.leads = [];
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const lead = event.detail.row;
        this.selectedLeadId = lead.Id;
        this.selectedLeadProjectType = lead.Government_Project__c; 
        this.selectedLeadMDApproved = lead.Managing_Director_Approved__c; 

        switch (actionName) {
            case 'approve':
                this.processApproval();
                break;
            case 'reject':
                this.isRejectModalOpen = true;
                break;
            case 'onhold':
                this.updateLeadStatus('On Hold', '');
                break;
            default:
                console.log('Unknown action');
        }
    }

    processApproval() {
        if (this.selectedLeadProjectType === 'Modules' && !this.selectedLeadMDApproved) {
            updateMDApproval({ leadId: this.selectedLeadId })
                .then(() => {
                    this.showToast('Success', 'Lead Approved.', 'success');
                    return refreshApex(this.wiredLeadResult);
                })
                .catch(error => {
                    console.error('Update error:', JSON.stringify(error));
                    this.showToast('Error', 'Error updating MD Approval.', 'error');
                });
        } else {
            this.updateLeadStatus('Approved', '');
        }
    }

    updateLeadStatus(status, reason, otherReason) {
        if (status === 'Rejected' && !reason.trim()) {
            this.showToast('Error', 'Please enter a reason for rejection.', 'error');
            return;
        }

        updateLeadStatus({ leadId: this.selectedLeadId, status, reason, otherReason })
            .then(() => {
                this.showToast('Success', `Lead status updated to ${status}`, 'success');
                return refreshApex(this.wiredLeadResult);
            })
            .catch(error => {
                console.error('Update error:', JSON.stringify(error));
                this.showToast('Error', 'Error updating lead', 'error');
            });
    }

    handleRejectionReasonChange(event) {
        this.selectedRejectionReason = event.detail.value;
        this.showOtherReasonField = (this.selectedRejectionReason === 'Others');
        if (!this.showOtherReasonField) {
            this.rejectionReason = '';
        }
    }

    handleReasonChange(event) {
        this.rejectionReason = event.target.value;
    }

    confirmReject() {
        let reasonToSend = this.selectedRejectionReason;
        let otherReason = '';

        if (!reasonToSend) {
            this.showToast('Error', 'Please select a rejection reason.', 'error');
            return;
        }

        if (reasonToSend === 'Others') {
            if (!this.rejectionReason.trim()) {
                this.showToast('Error', 'Please enter a reason for rejection.', 'error');
                return;
            }
            otherReason = this.rejectionReason;
        }

        this.updateLeadStatus('Rejected', reasonToSend, otherReason);
        this.isRejectModalOpen = false;
    }

    closeRejectModal() {
        this.isRejectModalOpen = false;
        this.rejectionReason = '';
        this.selectedRejectionReason = '';
        this.showOtherReasonField = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}