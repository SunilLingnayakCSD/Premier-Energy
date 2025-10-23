import { LightningElement, track, wire } from 'lwc';
import getOpportunitiesForApproval from '@salesforce/apex/OpportunityApprovalController.getOpportunitiesForApproval';
import approveOrRejectOpportunity from '@salesforce/apex/OpportunityApprovalController.approveOrRejectOpportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

const APPROVE = 'approve';
const REJECT = 'reject';

export default class OpportunityApprovalList extends NavigationMixin(LightningElement) {
    @track opportunities = [];
    @track isLoading = false;
    wiredOpportunitiesResult;

    columns = [
        {
            label: 'Opportunity Name',
            fieldName: 'Name',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'Name' },
                name: 'view_record',
                variant: 'base',
                title: 'View Opportunity',
                disabled: false
            }
        },
        { label: 'Owner', fieldName: 'OwnerName', type: 'text' },
        { label: 'Customer Type', fieldName: 'Customer_Type__c', type: 'text' },
        { label: 'Stage', fieldName: 'StageName', type: 'text' },
        {
            label: 'Approve',
            type: 'button',
            typeAttributes: {
                label: 'Approve',
                name: APPROVE,
                variant: 'brand',
                title: 'Approve this opportunity'
            }
        },
        {
            label: 'Reject',
            type: 'button',
            typeAttributes: {
                label: 'Reject',
                name: REJECT,
                variant: 'destructive',
                title: 'Reject this opportunity'
            }
        }
    ];

    connectedCallback() {
        console.log('Component connected. Loading opportunities...');
        this.loadOpportunities();
    }

    loadOpportunities() {
        this.isLoading = true;
        console.log('Fetching opportunities for approval...');
        getOpportunitiesForApproval()
            .then(result => {
                console.log('Opportunities retrieved:', result);
                this.opportunities = result.map(opp => ({
                    ...opp,
                    OwnerName: opp.Owner ? opp.Owner.Name : ''
                }));
                this.isLoading = false;
                console.log('Formatted opportunities:', this.opportunities);
            })
            .catch(error => {
                console.error('Error loading opportunities:', error);
                this.showToast('Error', 'Failed to load opportunities', 'error');
                this.isLoading = false;
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log(`Row action triggered: ${actionName}`, row);

        if (actionName === 'view_record') {
            this.navigateToRecord(row.Id);
        } else if (actionName === APPROVE || actionName === REJECT) {
            this.processAction(row.Id, actionName);
        }
    }

    navigateToRecord(oppId) {
        console.log(`Navigating to Opportunity record with Id: ${oppId}`);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: oppId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    processAction(oppId, action) {
        this.isLoading = true;
        console.log(`Processing action "${action}" for Opportunity Id: ${oppId}`);
        approveOrRejectOpportunity({ oppId, action })
            .then(() => {
                console.log(`Opportunity ${action}d successfully`);
                this.showToast('Success', `Opportunity ${action}d successfully`, 'success');
                this.opportunities = this.opportunities.filter(opp => opp.Id !== oppId);
                console.log('Updated opportunities list:', this.opportunities);
                this.isLoading = false;
            })
            .catch(error => {
                const message = error.body?.message || error.message || 'Unknown error';
                console.error(`Error during "${action}" action:`, error);
                this.showToast('Error', message, 'error');
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        console.log(`Toast: ${title} - ${message} [${variant}]`);
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}