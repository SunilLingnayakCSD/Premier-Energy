import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentUserRole from '@salesforce/apex/EBITDAApprovalController.getCurrentUserRole';
import getOpportunitiesForApproval from '@salesforce/apex/EBITDAApprovalController.getOpportunitiesForApproval';
import updateApprovalStatus from '@salesforce/apex/EBITDAApprovalController.updateApprovalStatus';

const COLUMNS = [
    { label: 'Opportunity Name', fieldName: 'Name', type: 'text' },
    { label: 'Segment', fieldName: 'Segment__c', type: 'text' },
    { label: 'DCR/NDCR', fieldName: 'DCR_Non_DCR__c', type: 'text' },
    { 
        label: 'EBITDA Margin', 
        fieldName: 'New_EBITDA_Margin__c', 
        type: 'percent', 
        typeAttributes: { 
            maximumFractionDigits: 2,
            minimumFractionDigits: 2
        } 
    },
    {
        label: 'Approve',
        type: 'button',
        typeAttributes: {
            label: 'Approve',
            name: 'approve',
            variant: 'brand',
            disabled: { fieldName: 'isDisabled' }
        }
    },
    {
        label: 'Reject',
        type: 'button',
        typeAttributes: {
            label: 'Reject',
            name: 'reject',
            variant: 'destructive',
            disabled: { fieldName: 'isDisabled' }
        }
    }
];

export default class EbitdaApproval extends LightningElement {
    @track opportunities = [];
    @track error;
    @track isLoading = true;
    columns = COLUMNS;
    userRole;

    connectedCallback() {
        console.log('EbitdaApproval component connected.');
        this.loadUserRole();
    }

    loadUserRole() {
        console.log('Loading user role...');
        getCurrentUserRole()
            .then((role) => {
                console.log('User role loaded:', role);
                this.userRole = role;
                this.loadOpportunities();
            })
            .catch((error) => {
                this.handleError('Failed to load user role', error);
            });
    }

    loadOpportunities() {
        console.log('Loading opportunities for role:', this.userRole);
        this.isLoading = true;
        getOpportunitiesForApproval({ userRole: this.userRole })
            .then(result => {
                console.log('Opportunities fetched:', result);
                this.opportunities = result.map(opp => ({
                    ...opp,
                    isDisabled: !this.isActionAllowed(opp)
                }));
                this.error = undefined;
            })
            .catch(error => {
                this.handleError('Error loading opportunities', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleError(message, error) {
        console.error(message, error);
        this.error = `${message}: ${error.body?.message || error.message}`;
        this.isLoading = false;
    }

    isActionAllowed(opportunity) {
        console.log('Checking if action is allowed for opportunity:', opportunity);
        if (this.isRegionalHead) {
            return true;
        } else if (this.isNationalHead && opportunity.National_Head_Approval__c == null) {
            return true;
        } else if (this.isManagingDirector && opportunity.National_Head_Approval__c === 'Approved') {
            return true;
        }
        return false;
    }

    get isRegionalHead() {
        console.log('Checking if user is Regional Head:', this.userRole);
        return this.userRole && [
            'East Region Head, Key Account Private',
            'West Region Head, Key Account Private',
            'South Region Head, Key Account Private',
            'North Region Head, Key Account Private'
        ].includes(this.userRole);
    }

    get isNationalHead() {
        console.log('Checking if user is National Head:', this.userRole);
        return this.userRole === 'National Head, Key Accounts Private';
    }

    get isManagingDirector() {
        console.log('Checking if user is Managing Director:', this.userRole);
        return this.userRole === 'Managing Director';
    }

    handleRowAction(event) {
        console.log('Row action triggered:', event.detail.action.name, event.detail.row);
        const action = event.detail.action.name;
        const row = event.detail.row;
        const status = action === 'approve' ? 'Approved' : 'Rejected';

        this.isLoading = true;
        updateApprovalStatus({ 
            opportunityId: row.Id, 
            userRole: this.userRole, 
            status 
        })
        .then(() => {
            this.showToast('Success', `Opportunity ${row.Name} has been ${status.toLowerCase()}`, 'success');
            console.log(`Opportunity ${row.Name} has been ${status.toLowerCase()}`);
            this.loadOpportunities(); // Refresh the data
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Update failed', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        console.log(`Toast: ${title} - ${message}`);
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}