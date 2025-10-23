import { LightningElement, wire, track } from 'lwc';
import getLeads from '@salesforce/apex/LeadApprovalController.getLeads';
import updateLeadStatus from '@salesforce/apex/LeadApprovalController.updateLeadStatus';
import updateMDApproval from '@salesforce/apex/LeadApprovalController.updateMDApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LeadApproval extends LightningElement {
    @track tenderLeads = [];
    @track preQualificationLeads = [];
    @track columnsTender = [];
    @track columnsPreQualification = [];
    @track userRoleName;

    @track isRejectModalOpen = false;
    @track isOnHoldModalOpen = false;
    @track rejectionReason = '';
    @track selectedRejectionReason = '';
    @track showOtherReasonField = false;
    @track onHoldReason = '';

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
            fieldName: 'leadIdLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Lead_ID__c' },
                target: '_blank'
            }
        },
        { label: 'OWNER NAME', fieldName: 'Owner_Name__c' },
        {
            label: 'APPROVE',
            type: 'button',
            typeAttributes: { label: 'Approve', name: 'approve', variant: 'brand' }
        },
        {
            label: 'REJECT',
            type: 'button',
            typeAttributes: { label: 'Reject', name: 'reject', variant: 'destructive' }
        }
    ];

    additionalColumns = [
        { label: 'LEAD CAPACITY', fieldName: 'Lead_Capacity__c' },
        { label: 'EMAIL ID', fieldName: 'Email', type: 'email' },
        { label: 'PHONE NO', fieldName: 'Phone', type: 'phone' },
        { label: 'REASON FOR ONHOLD', fieldName: 'Reason_for_On_Hold__c' }
    ];

    govAdditionalColumns = [
        { label: 'COUNTRY', fieldName: 'Country' },
        { label: 'STATE', fieldName: 'State' },
        { label: 'SCHEME Name', fieldName: 'Scheme_Name__c' }
    ];

get isNationalHead() {
    return this.userRoleName === 'National Head, Key Accounts Private';
}

get hasTenderLeads() {
    return this.tenderLeads && this.tenderLeads.length > 0;
}

    @wire(getLeads)
wiredLeads(result) {
    this.wiredLeadResult = result;
    const { error, data } = result;

    if (data) {
        this.userRoleName = data.userRoleName;

        const allLeads = data.leads.map(lead => ({
            ...lead,
            leadIdLink: `/lightning/r/Lead/${lead.Id}/view`,
            Reason_for_On_Hold__c: lead.Reason_for_On_Hold__c || 'ND',
            onHoldDisabled: !(
                this.userRoleName === 'National Head, Key Accounts Private' &&
                (lead.Status === 'Pre Qualification Request' || lead.Status === 'Re Request')
            )
        }));

        // Common logic for button columns
        const approveRejectButtons = [
            {
                label: 'APPROVE',
                type: 'button',
                typeAttributes: { label: 'Approve', name: 'approve', variant: 'brand' }
            },
            {
                label: 'REJECT',
                type: 'button',
                typeAttributes: { label: 'Reject', name: 'reject', variant: 'destructive' }
            }
        ];

        const onHoldButton = {
            label: 'ON HOLD',
            type: 'button',
            typeAttributes: {
                label: 'On Hold',
                name: 'onhold',
                variant: 'neutral',
                disabled: { fieldName: 'onHoldDisabled' }
            }
        };

        // Create baseColumns without buttons
        const baseColsWithoutButtons = [
            {
                label: 'LEAD ID',
                fieldName: 'leadIdLink',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Lead_ID__c' },
                    target: '_blank'
                }
            },
            { label: 'OWNER NAME', fieldName: 'Owner_Name__c' }
        ];

        const insertAfterOwnerName = (baseCols, extraCols) => {
            const ownerIndex = baseCols.findIndex(col => col.fieldName === 'Owner_Name__c');
            const newCols = [...baseCols];
            if (ownerIndex !== -1) {
                newCols.splice(ownerIndex + 1, 0, ...extraCols);
            }
            return newCols;
        };

        if (this.userRoleName === 'National Head, Key Accounts Private') {
            this.tenderLeads = allLeads.filter(lead => lead.Status === 'Tender Participation Request');
            this.preQualificationLeads = allLeads.filter(
                lead => lead.Status === 'Pre Qualification Request' || lead.Status === 'Re Request'
            );

            // Tender columns (gov + buttons)
            const tenderCols = insertAfterOwnerName(baseColsWithoutButtons, this.govAdditionalColumns);
            this.columnsTender = [...tenderCols, ...approveRejectButtons];

            // Pre-qualification columns (additional + all buttons)
            const preQualCols = insertAfterOwnerName(baseColsWithoutButtons, this.additionalColumns);
            this.columnsPreQualification = [...preQualCols, ...approveRejectButtons, onHoldButton];
        } else {
            this.tenderLeads = allLeads.filter(lead => lead.Status === 'Tender Participation Request');
            const tenderCols = insertAfterOwnerName(baseColsWithoutButtons, this.govAdditionalColumns);
            this.columnsTender = [...tenderCols, ...approveRejectButtons];
            this.columnsPreQualification = []; // Hide extra table for other roles
        }
    } else if (error) {
        console.error('Error fetching leads:', error);
    }
}


    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const lead = event.detail.row;
        this.selectedLeadId = lead.Id;
        this.selectedLeadProjectType = lead.Government_Project__c;
        this.selectedLeadMDApproved = lead.Managing_Director_Approved__c;

        switch (actionName) {
            case 'approve': this.processApproval(); break;
            case 'reject': this.isRejectModalOpen = true; break;
            case 'onhold': this.isOnHoldModalOpen = true; break;
        }
    }

    processApproval() {
        if ((['Modules', 'Water Pumps', 'EPC'].includes(this.selectedLeadProjectType)) && !this.selectedLeadMDApproved) {
            updateMDApproval({ leadId: this.selectedLeadId })
                .then(() => this.showToast('Success', 'Lead Approved.', 'success'))
                .then(() => refreshApex(this.wiredLeadResult))
                .catch(err => this.showToast('Error', 'Error updating MD Approval.', 'error'));
        } else {
            this.updateLeadStatus('Approved', '');
        }
    }

    updateLeadStatus(status, reason, otherReason = '') {
        updateLeadStatus({ leadId: this.selectedLeadId, status, reason, otherReason })
            .then(() => {
                this.showToast('Success', `Lead status updated to ${status}`, 'success');
                this.isRejectModalOpen = false;
                this.isOnHoldModalOpen = false;
                return refreshApex(this.wiredLeadResult);
            })
            .catch(error => {
                this.showToast('Error', 'Error updating lead', 'error');
            });
    }

    handleRejectionReasonChange(event) {
        this.selectedRejectionReason = event.detail.value;
        this.showOtherReasonField = (this.selectedRejectionReason === 'Others');
    }

    handleReasonChange(event) {
        this.rejectionReason = event.target.value;
    }

    confirmReject() {
        const reason = this.selectedRejectionReason;
        const other = reason === 'Others' ? this.rejectionReason.trim() : '';
        if (!reason || (reason === 'Others' && !other)) {
            this.showToast('Error', 'Please provide a valid reason.', 'error');
            return;
        }
        this.updateLeadStatus('Rejected', reason, other);
    }

    confirmOnHold() {
        if (!this.onHoldReason.trim()) {
            this.showToast('Error', 'Please enter reason for On Hold.', 'error');
            return;
        }
        this.updateLeadStatus('On Hold', this.onHoldReason);
    }

    closeRejectModal() {
        this.isRejectModalOpen = false;
        this.rejectionReason = '';
        this.selectedRejectionReason = '';
        this.showOtherReasonField = false;
    }

    closeOnHoldModal() {
        this.isOnHoldModalOpen = false;
        this.onHoldReason = '';
    }

    handleOnHoldReasonChange(event) {
        this.onHoldReason = event.target.value;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}