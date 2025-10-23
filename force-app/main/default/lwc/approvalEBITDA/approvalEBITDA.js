import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCurrentUserRole from '@salesforce/apex/ApproveEBITDA.getCurrentUserRole';
import getDomesticOppforNH from '@salesforce/apex/ApproveEBITDA.getDomesticOppforNH';
import getCellDomesticOppforNH from '@salesforce/apex/ApproveEBITDA.getCellDomesticOppforNH';
import getDomesticOppforMD from '@salesforce/apex/ApproveEBITDA.getDomesticOppforMD';
import getModuleCellExportOppforMD from '@salesforce/apex/ApproveEBITDA.getModuleCellExportOppforMD';
import getEportCellModuleInternational from '@salesforce/apex/ApproveEBITDA.getEportCellModuleInternational';
import approveDomesticByNH from '@salesforce/apex/ApproveEBITDA.approveDomesticByNH';
import rejectOpportunity from '@salesforce/apex/ApproveEBITDA.rejectOpportunity';
import escalateOpportunity from '@salesforce/apex/ApproveEBITDA.escalateOpportunity';
import saveManualEbita from '@salesforce/apex/ApproveEBITDA.saveManualEbita';
import approveDomesticByMD from '@salesforce/apex/ApproveEBITDA.approveDomesticByMD';
import rejectOpportunitybyMD from '@salesforce/apex/ApproveEBITDA.rejectOpportunitybyMD';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApprovalEBITDA extends NavigationMixin(LightningElement) {
    userRole;
    @track isNationalHead = false;
    @track isMD = false;
    @track isInternational = false;
    @track domesticOppNH = [];
    @track allOpportunitiesforNH = [];
    @track showRejectModal = false;
    @track selectedOpportunityId = '';
    @track rejectComment = '';
    @track showEscalateModal = false;
    @track escalateComment = '';
    @track cellOppNH = [];
    @track isEdited = false;
    @track isSaveEbitda = false;
    @track editedOppMap = new Map();
    @track internationalOpp = [];
    @track isEditedInter = false;
    @track domesticOppMD = [];
    @track cellOppMD = [];
    @track showRejectModalforMD = false;
    @track isEditedMD = false;
    @track allOpportunitiesforMD = [];
    @track isApproveByNH = false;
    @track isRejectByNH = false;
    @track isEscalateByNH = false;
    @track isApproveByMD = false;
    @track isRejectByMD = false;

    @wire(getCurrentUserRole)
    wiredRole({ error, data }) {
        if (data) {
            this.userRole = data;
            console.log('userRole--> : ', this.userRole);
            if (this.userRole == 'National Head, Key Accounts Private' || this.userRole == 'CEO') {
                this.isNationalHead = true;
               // this.loadDomesticOppforNH();
                //this.loadDomesticCellOppforNH();
                this.loadOppforNH();
            }
            if (this.userRole == 'Managing Director' || this.userRole == 'CEO') {
                this.isMD = true;
                // this.loadDomesticOppforMD();
                // this.loadExportCellOppforMD();
                this.loadOppforMD();
            }

            if (this.userRole == 'Key Accounts International Head Private' || this.userRole == 'CEO') {
                this.isInternational = true;
                this.loadOppforInternational();
            }
        } else if (error) {
            console.error('Error retrieving user role:', error);
        }
    }

    loadOppforNH(){
        getDomesticOppforNH().then((result) => {
            console.log('getDomesticOppforNH result--> : ', result);
            this.domesticOppNH = result.map(opp => {
                const newebitda = parseFloat(opp.New_EBITDA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEdited || (preApproved > newebitda),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: false,
                    isEditingEbitda: false
                };
            });
            this.allOpportunitiesforNH = [...this.allOpportunitiesforNH, ...this.domesticOppNH];
            getCellDomesticOppforNH().then((result) => {
            console.log('getCellDomesticOppforNH result--> : ', result);
            this.cellOppNH = result.map(opp => {
                const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEdited || (preApproved > manual),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: true,
                    isEditingEbitda: true
                };
            });
            this.allOpportunitiesforNH = [...this.allOpportunitiesforNH, ...this.cellOppNH];
        }).catch((err) => {
            console.log('getCellDomesticOppforNH err : ', err);
        });
        }).catch((err) => {
            console.log('getDomesticOppforNH err : ', err);
        });
        
        console.log('allOpportunitiesforNH--> : ',JSON.stringify(this.allOpportunitiesforNH));
        return this.allOpportunitiesforNH;
    }

    loadOppforMD(){
         getDomesticOppforMD().then((result) => {
            console.log('getDomesticOppforMD result--> : ', result);
            this.domesticOppMD = result.map(opp => {
                const newebitda = parseFloat(opp.New_EBITDA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEditedMD || (preApproved > newebitda),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: false,
                    isEditingEbitda: false
                };
            });
            this.allOpportunitiesforMD = [...this.allOpportunitiesforMD, ...this.domesticOppMD];
            getModuleCellExportOppforMD().then((result) => {
            console.log('getModuleCellExportOppforMD result--> : ', result);
            this.cellOppMD = result.map(opp => {
                const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEditedMD || (preApproved > manual),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: true,
                    isEditingEbitda: true
                };
            });
            this.allOpportunitiesforMD = [...this.allOpportunitiesforMD, ...this.cellOppMD];
        }).catch((err) => {
            console.log('getModuleCellExportOppforMD err : ', err);
        });
        }).catch((err) => {
            console.log('getDomesticOppforMD err : ', err);
        });
    }

    /*loadDomesticOppforNH() {
        return getDomesticOppforNH().then((result) => {
            console.log('getDomesticOppforNH result--> : ', result);
            this.domesticOppNH = result.map(opp => {
                const newebitda = parseFloat(opp.New_EBITDA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEdited || (preApproved > newebitda),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: false
                };
            });
        }).catch((err) => {
            console.log('getDomesticOppforNH err : ', err);
        });
    }

    loadDomesticCellOppforNH() {
        return getCellDomesticOppforNH().then((result) => {
            console.log('getCellDomesticOppforNH result--> : ', result);
            this.cellOppNH = result.map(opp => {
                const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEdited || (preApproved > manual),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: true
                };
            });
        }).catch((err) => {
            console.log('getCellDomesticOppforNH err : ', err);
        });
    }

    loadDomesticOppforMD() {
       return getDomesticOppforMD().then((result) => {
            console.log('getDomesticOppforMD result--> : ', result);
            this.domesticOppMD = result.map(opp => {
                const newebitda = parseFloat(opp.New_EBITDA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEditedMD || (preApproved > newebitda),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: false
                };
            });
        }).catch((err) => {
            console.log('getDomesticOppforMD err : ', err);
        });
    }

    loadExportCellOppforMD() {
       return getModuleCellExportOppforMD().then((result) => {
            console.log('getModuleCellExportOppforMD result--> : ', result);
            this.cellOppMD = result.map(opp => {
                const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEditedMD || (preApproved > manual),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: true
                };
            });
        }).catch((err) => {
            console.log('getModuleCellExportOppforMD err : ', err);
        });
    }*/

    loadOppforInternational() {
       return getEportCellModuleInternational().then((result) => {
            console.log('getEportCellModuleInternational result--> : ', result);
            this.internationalOpp = result.map(opp => {
                const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
                const preApproved = parseFloat(opp.AOP_Ebitda__c || 0);
                return {
                    ...opp,
                    isButtonDisabled: this.isEditedInter || (preApproved > manual),
                    recordUrl: this.getRecordUrl(opp.Id),
                    isManual: true,
                    isEditingEbitda: true
                };
            });
        }).catch((err) => {
            console.log('getEportCellModuleInternational err : ', err);
        });
    }

    getRecordUrl(recordId) {
        return `/lightning/r/Opportunity/${recordId}/view`;
    }

    get hasInternationalOpp() {
        return Array.isArray(this.internationalOpp) && this.internationalOpp.length > 0;
    }

    get hasDomesticModuleOppforNH() {
        return Array.isArray(this.allOpportunitiesforNH) && this.allOpportunitiesforNH.length > 0;
    }

    get hasDomestCellOppforNH() {
        return Array.isArray(this.cellOppNH) && this.cellOppNH.length > 0;
    }

    get hasDomestModuleOppforMD() {
        return Array.isArray(this.allOpportunitiesforMD) && this.allOpportunitiesforMD.length > 0;
    }

    get hasCellOppforMD() {
        return Array.isArray(this.cellOppMD) && this.cellOppMD.length > 0;
    }

    handleEbitaChange(event) {
       
        const oppId = event.target.dataset.id;
        const newValue = parseFloat(event.target.value);

        if (this.isNationalHead) {
             this.isApproveByNH = true;
        this.isRejectByNH = true;
        this.isEscalateByNH = true;
            this.allOpportunitiesforNH = this.allOpportunitiesforNH.map(opp => {
                if (opp.Id === oppId) {
                    const updatedOpp = { ...opp, Manual_EBIDTA__c: newValue };
                    this.editedOppMap.set(oppId, updatedOpp);
                    return updatedOpp;
                }
                return opp;
            });

            this.isEdited = true;
            this.updateButtonDisabledFlags();
        }

        if (this.isMD) {
            this.isApproveByMD = true;
            this.isRejectByMD = true;
            this.allOpportunitiesforMD = this.allOpportunitiesforMD.map(opp => {
                if (opp.Id === oppId) {
                    const updatedOpp = { ...opp, Manual_EBIDTA__c: newValue };
                    this.editedOppMap.set(oppId, updatedOpp);
                    return updatedOpp;
                }
                return opp;
            });

            this.isEditedMD = true;
            this.updateButtonDisabledFlagsMD();
        }

        if (this.isInternational) {
             this.isApproveByNH = true;
        this.isRejectByNH = true;
        this.isEscalateByNH = true;
            this.internationalOpp = this.internationalOpp.map(opp => {
                if (opp.Id === oppId) {
                    const updatedOpp = { ...opp, Manual_EBIDTA__c: newValue };
                    this.editedOppMap.set(oppId, updatedOpp);
                    return updatedOpp;
                }
                return opp;
            });

            this.isEditedInter = true;
            this.updateButtonDisabledFlagsInter();
        }
    }

    updateButtonDisabledFlags() {
        this.allOpportunitiesforNH = this.allOpportunitiesforNH.map(opp => {
            return {
                ...opp,
                isButtonDisabled: this.isEdited || (opp.AOP_Ebitda__c > opp.Manual_EBIDTA__c)
            };
        });
    }

    updateButtonDisabledFlagsInter() {
        this.internationalOpp = this.internationalOpp.map(opp => {
            return {
                ...opp,
                isButtonDisabled: this.isEditedInter || (opp.AOP_Ebitda__c > opp.Manual_EBIDTA__c)
            };
        });
    }

    updateButtonDisabledFlagsMD() {
        this.allOpportunitiesforMD = this.allOpportunitiesforMD.map(opp => {
            return {
                ...opp,
                isButtonDisabled: this.isEditedMD || (opp.AOP_Ebitda__c > opp.Manual_EBIDTA__c)
            };
        });
    }

    saveUpdatedEbita() {
        this.isSaveEbitda = true;

        const updatedData = Array.from(this.editedOppMap.values()).map(opp => ({
            Id: opp.Id,
            Manual_EBIDTA__c: opp.Manual_EBIDTA__c
        }));
        console.log('updateData--> : ', JSON.stringify(updatedData));
        if (updatedData.length === 0) {
            this.isSaveEbitda = false;
            this.showErrorToast('No changes to save.');
            return;
        }
        updatedData.forEach((opp, index) => {
    console.log(`opp[${index}] Id=${opp.Id}, Manual_EBIDTA__c=`, opp.Manual_EBIDTA__c, ' type=', typeof opp.Manual_EBIDTA__c);
});

        const emptyOpps = updatedData.filter(opp => 
    opp.Manual_EBIDTA__c == null || 
    opp.Manual_EBIDTA__c === '' || 
    opp.Manual_EBIDTA__c === 'null' ||
    Number.isNaN(opp.Manual_EBIDTA__c)
);
    console.log('emptyOpps len--> : ',JSON.stringify(emptyOpps));

    if (emptyOpps.length > 0) {
    this.isSaveEbitda = false;
    this.showErrorToast('Manual Ebitda should not be blank');
    return;
}

        saveManualEbita({ updatedOppList: updatedData })
            .then(() => {
                this.isEdited = false;
                this.isEditedInter = false;
                this.isEditedMD = false;
                this.showSuccessToast('Manual Ebitda Saved..');
                this.isSaveEbitda = false;
                this.domesticOppNH = [...this.domesticOppNH];
                this.cellOppNH = [...this.cellOppNH];
                this.allOpportunitiesforNH = [...this.allOpportunitiesforNH];
                this.allOpportunitiesforMD = [...this.allOpportunitiesforMD];
                this.cellOppMD = [...this.cellOppMD];
                this.internationalOpp = [...this.internationalOpp];
                this.domesticOppMD = [...this.domesticOppMD];
                this.updateButtonDisabledFlags();
                this.updateButtonDisabledFlagsInter();
                this.updateButtonDisabledFlagsMD();
                this.editedOppMap.clear();
                this.isApproveByMD = false;
                this.isApproveByNH = false;
                this.isEscalateByNH = false;
                this.isRejectByMD = false;
                this.isRejectByNH = false;
            })
            .catch(error => {
                console.error('Error saving EBITDA', error);
                this.isSaveEbitda = false;
                this.showErrorToast('Error saving data');
            });
    }

    handleApproveDomesticNH(event) {
        this.isApproveByNH = true;
        const oppId = event.target.dataset.id;
        console.log('Approve clicked for Opportunity ID: ', oppId);
        approveDomesticByNH({ OppId: oppId }).then((result) => {
            console.log('approveDomesticByNH result--> : ', result);
            if(result == 'approved'){
                this.showSuccessToast('Approved');
            this.domesticOppNH = this.domesticOppNH.filter(opp => opp.Id !== oppId);
            this.cellOppNH = this.cellOppNH.filter(opp => opp.Id !== oppId);
            this.allOpportunitiesforNH = this.allOpportunitiesforNH.filter(opp => opp.Id !== oppId);
            this.internationalOpp = this.internationalOpp.filter(opp => opp.Id !== oppId);
            this.isApproveByNH = false;
            }else{
                this.showErrorToast('Manual EBITDA is required. Kindly provide a value before proceeding.');
            }
            
        }).catch((err) => {
            console.log('approveDomesticByNH err : ', err);
            this.showErrorToast('Error approving opportunity');
            this.isApproveByNH = false;
        });
    }

    handleApproveDomesticMD(event) {
        this.isApproveByMD = true;
        const oppId = event.target.dataset.id;
        console.log('Approve clicked for Opportunity ID: ', oppId);
        approveDomesticByMD({ OppId: oppId }).then((result) => {
            console.log('approveDomesticByMD result--> : ', result);
            if(result == 'approved'){
            this.showSuccessToast('Approved');
            this.cellOppMD = this.cellOppMD.filter(opp => opp.Id !== oppId);
            this.domesticOppMD = this.domesticOppMD.filter(opp => opp.Id !== oppId);
            this.allOpportunitiesforMD = this.allOpportunitiesforMD.filter(opp => opp.Id !== oppId);
            this.isApproveByMD = false;
            }else{
                 this.showErrorToast('Manual EBITDA is required. Kindly provide a value before proceeding.');
            }
        }).catch((err) => {
            console.log('approveDomesticByMD err : ', err);
            this.showErrorToast('Error approving opportunity');
            this.isApproveByMD = false;
        });
    }

    handleRejectDomesticNH(event) {
        this.isRejectByNH = true;
        const oppId = event.target.dataset.id;
        console.log('Reject clicked for Opportunity ID: ', oppId);
        this.selectedOpportunityId = oppId;
        this.showRejectModal = true;
    }

    handleRejectDomesticMD(event) {
        this.isRejectByMD = true;
        const oppId = event.target.dataset.id;
        console.log('Reject clicked for Opportunity ID: ', oppId);
        this.selectedOpportunityId = oppId;
        this.showRejectModalforMD = true;
    }

    handleEscalateDomesticNH(event) {
        const oppId = event.target.dataset.id;
        console.log('Escalate clicked for Opportunity ID: ', oppId);
        this.selectedOpportunityId = oppId;
        this.showEscalateModal = true;
        this.isEscalateByNH = true;
    }

    closeRejectModal() {
        this.showRejectModal = false;
        this.showRejectModalforMD = false;
        this.rejectComment = '';
    }

    closeEscalateModal() {
        this.showEscalateModal = false;
        this.escalateComment = '';
    }

    handleCommentChange(event) {
        this.rejectComment = event.target.value;
    }

    handleEscalateCommentChange(event) {
        this.escalateComment = event.target.value;
    }

    submitReject() {
        if (!this.rejectComment || this.rejectComment.trim() === '') {
            this.showErrorToast('Please enter a comment before rejecting.');
            return;
        }
        console.log('Rejected Opportunity ID:', this.selectedOpportunityId);
        console.log('Rejection Comment:', this.rejectComment);

        rejectOpportunity({ OppId: this.selectedOpportunityId, comment: this.rejectComment })
            .then(() => {
                this.showSuccessToast('Rejected');
                this.showRejectModal = false;
                this.rejectComment = '';
               this.domesticOppNH = this.domesticOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
               this.cellOppNH = this.cellOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
               this.allOpportunitiesforNH = this.allOpportunitiesforNH.filter(opp => opp.Id !== this.selectedOpportunityId);
               this.internationalOpp = this.internationalOpp.filter(opp => opp.Id !== this.selectedOpportunityId);
               this.isRejectByNH = false;
            })
            .catch(error => {
                console.error(error);
                this.showErrorToast('Error rejecting opportunity');
                this.isRejectByNH = false;
            });


        this.showRejectModal = false;
        this.rejectComment = '';
    }

    submitRejectbyMD() {
        if (!this.rejectComment || this.rejectComment.trim() === '') {
            this.showErrorToast('Please enter a comment before rejecting.');
            return;
        }
        console.log('Rejected Opportunity ID:', this.selectedOpportunityId);
        console.log('Rejection Comment:', this.rejectComment);

        rejectOpportunitybyMD({ OppId: this.selectedOpportunityId, comment: this.rejectComment })
            .then(() => {
                this.showSuccessToast('Rejected');
                this.showRejectModalforMD = false;
                this.rejectComment = '';
                this.cellOppMD = this.cellOppMD.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.domesticOppMD = this.domesticOppMD.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.allOpportunitiesforMD = this.allOpportunitiesforMD.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.isRejectByMD = false;
            })
            .catch(error => {
                console.error(error);
                this.showErrorToast('Error rejecting opportunity');
                this.isRejectByMD = false;
            });


        this.showRejectModalforMD = false;
        this.rejectComment = '';
    }

    submitEscalate() {
        console.log('Escalation Opportunity ID:', this.selectedOpportunityId);
        console.log('Escalation Comment:', this.escalateComment);

        escalateOpportunity({ OppId: this.selectedOpportunityId, comment: this.escalateComment })
            .then((result) => {
                console.log('escalate result : ',result);
                if(result == 'approved'){
                this.showSuccessToast('Escalated');
                this.showEscalateModal = false;
                this.escalateComment = '';
                this.domesticOppNH = this.domesticOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.cellOppNH = this.cellOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.internationalOpp = this.internationalOpp.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.allOpportunitiesforMD = this.allOpportunitiesforMD.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.allOpportunitiesforNH = this.allOpportunitiesforNH.filter(opp => opp.Id !== this.selectedOpportunityId);
                this.isEscalateByNH = false;
                }else{
                    this.showErrorToast('Manual EBITDA is required. Kindly provide a value before proceeding.');
                }
            })
            .catch(error => {
                console.error(error);
                this.showErrorToast('Error escalating opportunity');
                this.isEscalateByNH = false;
            });


        this.showEscalateModal = false;
        this.escalateComment = '';
    }

    showSuccessToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        });
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}



// import { LightningElement, wire, track } from 'lwc';
// import getCurrentUserRole from '@salesforce/apex/ApproveEBITDA.getCurrentUserRole';
// import getDomesticOppforNH from '@salesforce/apex/ApproveEBITDA.getDomesticOppforNH';
// import getCellDomesticOppforNH from '@salesforce/apex/ApproveEBITDA.getCellDomesticOppforNH';
// import getDomesticOppforMD from '@salesforce/apex/ApproveEBITDA.getDomesticOppforMD';
// import getModuleCellExportOppforMD from '@salesforce/apex/ApproveEBITDA.getModuleCellExportOppforMD';
// import getEportCellModuleInternational from '@salesforce/apex/ApproveEBITDA.getEportCellModuleInternational';
// import approveDomesticByNH from '@salesforce/apex/ApproveEBITDA.approveDomesticByNH';
// import rejectOpportunity from '@salesforce/apex/ApproveEBITDA.rejectOpportunity';
// import escalateOpportunity from '@salesforce/apex/ApproveEBITDA.escalateOpportunity';
// import saveManualEbita from '@salesforce/apex/ApproveEBITDA.saveManualEbita';
// import approveDomesticByMD from '@salesforce/apex/ApproveEBITDA.approveDomesticByMD';
// import rejectOpportunitybyMD from '@salesforce/apex/ApproveEBITDA.rejectOpportunitybyMD';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// export default class ApprovalEBITDA extends LightningElement {

//     userRole;
//     @track isNationalHead = false;
//     @track isMD = false;
//     @track isInternational = false;
//     @track domesticOppNH = [];
//     @track showRejectModal = false;
//     @track selectedOpportunityId = '';
//     @track rejectComment = '';
//     @track showEscalateModal = false;
//     @track escalateComment = '';
//     @track cellOppNH = [];
//     @track isEdited = false;
//     @track isSaveEbitda = false;
//     @track editedOppMap = new Map();
//     @track internationalOpp = [];
//     @track isEditedInter = false;
//     @track domesticOppMD = [];
//     @track cellOppMD = [];
//     @track showRejectModalforMD = false;
//     @track isEditedMD = false;


//     @wire(getCurrentUserRole)
//     wiredRole({ error, data }) {
//         if (data) {
//             this.userRole = data;
//             console.log('userRole--> : ', this.userRole);
//             if (this.userRole == 'National Head, Key Accounts Private' || this.userRole == 'CEO') {
//                 this.isNationalHead = true;
//                 this.loadDomesticOppforNH();
//                 this.loadDomesticCellOppforNH();
//             }
//             if (this.userRole == 'Managing Director' || this.userRole == 'CEO') {
//                 this.isMD = true;
//                 this.loadDomesticOppforMD();
//                 this.loadExportCellOppforMD();
//             }

//             if (this.userRole == 'Key Accounts International Head Private' || this.userRole == 'CEO') {
//                 this.isInternational = true;
//                 this.loadOppforInternational();
//             }
//         } else if (error) {
//             console.error('Error retrieving user role:', error);
//         }
//     }

//     loadDomesticOppforNH() {
//         return getDomesticOppforNH().then((result) => {
//             console.log('getDomesticOppforNH result--> : ', result);
//             this.domesticOppNH = result;
//             console.log('domesticOppNH--> : ', this.domesticOppNH);
//             this.domesticOppNH = result.map(opp => {
//                 const newebitda = parseFloat(opp.New_EBITDA__c || 0);
//                 const preApproved = parseFloat(opp.Pre_Approved_EBITDA__c || 0);
//                 return {
//                     ...opp,
//                     isButtonDisabled: this.isEdited || (preApproved > newebitda)
//                 };
//             });
//         }).catch((err) => {
//             console.log('getDomesticOppforNH err : ', err);
//         });
//     }
//     loadDomesticCellOppforNH() {
//         return getCellDomesticOppforNH().then((result) => {
//             console.log('getCellDomesticOppforNH result--> : ', result);
//             this.cellOppNH = result;
//             this.cellOppNH = result.map(opp => {
//                 const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
//                 const preApproved = parseFloat(opp.Pre_Approved_EBITDA__c || 0);
//                 return {
//                     ...opp,
//                     isButtonDisabled: this.isEdited || (preApproved > manual)
//                 };
//             });

//         }).catch((err) => {
//             console.log('getCellDomesticOppforNH err : ', err);
//         });

//     }
//     loadDomesticOppforMD() {
//        return getDomesticOppforMD().then((result) => {
//             console.log('getDomesticOppforMD result--> : ', result);
//             this.domesticOppMD = result;
//             this.domesticOppMD = result.map(opp => {
//                 const newebitda = parseFloat(opp.New_EBITDA__c || 0);
//                 const preApproved = parseFloat(opp.Pre_Approved_EBITDA__c || 0);
//                 return {
//                     ...opp,
//                     isButtonDisabled: this.isEditedMD || (preApproved > newebitda)
//                 };
//             });

//         }).catch((err) => {
//             console.log('getDomesticOppforMD err : ', err);
//         });
//     }
//     loadExportCellOppforMD() {
//        return getModuleCellExportOppforMD().then((result) => {
//             console.log('getModuleCellExportOppforMD result--> : ', result);
//             this.cellOppMD = result.map(opp => {
//                 const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
//                 const preApproved = parseFloat(opp.Pre_Approved_EBITDA__c || 0);
//                 return {
//                     ...opp,
//                     isButtonDisabled: this.isEditedMD || (preApproved > manual)
//                 };
//             });
//         }).catch((err) => {
//             console.log('getModuleCellExportOppforMD err : ', err);
//         });
//     }
//     loadOppforInternational() {
//        return getEportCellModuleInternational().then((result) => {
//             console.log('getEportCellModuleInternational result--> : ', result);
//             this.internationalOpp = result.map(opp => {
//                 const manual = parseFloat(opp.Manual_EBIDTA__c || 0);
//                 const preApproved = parseFloat(opp.Pre_Approved_EBITDA__c || 0);
//                 return {
//                     ...opp,
//                     isButtonDisabled: this.isEditedInter || (preApproved > manual)
//                 };
//             });
//         }).catch((err) => {
//             console.log('getEportCellModuleInternational err : ', err);
//         });
//     }

//     get hasInternationalOpp() {
//         return Array.isArray(this.internationalOpp) && this.internationalOpp.length > 0;
//     }

//     get hasDomesticModuleOppforNH() {
//         return Array.isArray(this.domesticOppNH) && this.domesticOppNH.length > 0;
//     }

//     get hasDomestCellOppforNH() {
//         return Array.isArray(this.cellOppNH) && this.cellOppNH.length > 0;
//     }

//     get hasDomestModuleOppforMD() {
//         return Array.isArray(this.domesticOppMD) && this.domesticOppMD.length > 0;
//     }

//     get hasCellOppforMD() {
//         return Array.isArray(this.cellOppMD) && this.cellOppMD.length > 0;
//     }

//     handleEbitaChange(event) {
//         const oppId = event.target.dataset.id;
//         const newValue = parseFloat(event.target.value);

//         if (this.isNationalHead) {
//             this.cellOppNH = this.cellOppNH.map(opp => {
//                 if (opp.Id === oppId) {
//                     const updatedOpp = { ...opp, Manual_EBIDTA__c: newValue };
//                     this.editedOppMap.set(oppId, updatedOpp);
//                     return updatedOpp;
//                 }
//                 return opp;
//             });

//             this.isEdited = true;
//             this.updateButtonDisabledFlags();
//         }

//         if (this.isMD) {
//             this.cellOppMD = this.cellOppMD.map(opp => {
//                 if (opp.Id === oppId) {
//                     const updatedOpp = { ...opp, Manual_EBIDTA__c: newValue };
//                     this.editedOppMap.set(oppId, updatedOpp);
//                     return updatedOpp;
//                 }
//                 return opp;
//             });

//             this.isEditedMD = true;
//             this.updateButtonDisabledFlagsMD();
//         }

//         if (this.isInternational) {
//             this.internationalOpp = this.internationalOpp.map(opp => {
//                 if (opp.Id === oppId) {
//                     const updatedOpp = { ...opp, Manual_EBIDTA__c: newValue };
//                     this.editedOppMap.set(oppId, updatedOpp);
//                     return updatedOpp;
//                 }
//                 return opp;
//             });

//             this.isEditedInter = true;
//             this.updateButtonDisabledFlagsInter();
//         }
//     }
//     updateButtonDisabledFlags() {
//         this.cellOppNH = this.cellOppNH.map(opp => {
//             return {
//                 ...opp,
//                 isButtonDisabled: this.isEdited || (opp.Pre_Approved_EBITDA__c > opp.Manual_EBIDTA__c)
//             };
//         });
//     }

//     updateButtonDisabledFlagsInter() {
//         this.internationalOpp = this.internationalOpp.map(opp => {
//             return {
//                 ...opp,
//                 isButtonDisabled: this.isEditedInter || (opp.Pre_Approved_EBITDA__c > opp.Manual_EBIDTA__c)
//             };
//         });
//     }

//     updateButtonDisabledFlagsMD() {
//         this.cellOppMD = this.cellOppMD.map(opp => {
//             return {
//                 ...opp,
//                 isButtonDisabled: this.isEditedMD || (opp.Pre_Approved_EBITDA__c > opp.Manual_EBIDTA__c)
//             };
//         });
//     }


//     saveUpdatedEbita() {
//         this.isSaveEbitda = true;
//         const updatedData = Array.from(this.editedOppMap.values()).map(opp => ({
//             Id: opp.Id,
//             Manual_EBIDTA__c: opp.Manual_EBIDTA__c
//         }));
//         console.log('updateData--> : ', JSON.stringify(updatedData));
//         if (updatedData.length === 0) {
//             this.isSaveEbitda = false;
//             this.showErrorToast('No changes to save.');
//             return;
//         }

//         saveManualEbita({ updatedOppList: updatedData })
//             .then(() => {
//                 this.isEdited = false;
//                 this.isEditedInter = false;
//                 this.isEditedMD = false;
//                 this.showSuccessToast('Manual Ebitda Saved..');
//                 this.isSaveEbitda = false;
//                 this.domesticOppNH = [...this.domesticOppNH];
//                 this.cellOppNH = [...this.cellOppNH];
//                 this.cellOppMD = [...this.cellOppMD];
//                 this.internationalOpp = [...this.internationalOpp];
//                 this.domesticOppMD = [...this.domesticOppMD];
//                 this.updateButtonDisabledFlags();
//                 this.updateButtonDisabledFlagsInter();
//                 this.updateButtonDisabledFlagsMD();
//                 this.editedOppMap.clear();
//             })
//             .catch(error => {
//                 console.error('Error saving EBITDA', error);
//                 this.isSaveEbitda = false;
//                 this.showErrorToast('Error saving data');
//             });
//     }



//     handleApproveDomesticNH(event) {
//         const oppId = event.target.dataset.id;
//         console.log('Approve clicked for Opportunity ID: ', oppId);
//         approveDomesticByNH({ OppId: oppId }).then((result) => {
//             console.log('approveDomesticByNH result--> : ', result);
//             this.showSuccessToast('Approved');
//             this.domesticOppNH = this.domesticOppNH.filter(opp => opp.Id !== oppId);
//             this.cellOppNH = this.cellOppNH.filter(opp => opp.Id !== oppId);
//             this.internationalOpp = this.internationalOpp.filter(opp => opp.Id !== oppId);
//         }).catch((err) => {
//             console.log('approveDomesticByNH err : ', err);
//             this.showErrorToast('Error approving opportunity');
//         });
//     }

//     handleApproveDomesticMD(event) {
//         const oppId = event.target.dataset.id;
//         console.log('Approve clicked for Opportunity ID: ', oppId);
//         approveDomesticByMD({ OppId: oppId }).then((result) => {
//             console.log('approveDomesticByMD result--> : ', result);
//             this.showSuccessToast('Approved');
//             this.cellOppMD = this.cellOppMD.filter(opp => opp.Id !== oppId);
//             this.domesticOppMD = this.domesticOppMD.filter(opp => opp.Id !== oppId);
//         }).catch((err) => {
//             console.log('approveDomesticByMD err : ', err);
//             this.showErrorToast('Error approving opportunity');
//         });
//     }

//     handleRejectDomesticNH(event) {
//         const oppId = event.target.dataset.id;
//         console.log('Reject clicked for Opportunity ID: ', oppId);
//         this.selectedOpportunityId = oppId;
//         this.showRejectModal = true;
//     }

//     handleRejectDomesticMD(event) {
//         const oppId = event.target.dataset.id;
//         console.log('Reject clicked for Opportunity ID: ', oppId);
//         this.selectedOpportunityId = oppId;
//         this.showRejectModalforMD = true;
//     }

//     handleEscalateDomesticNH(event) {
//         const oppId = event.target.dataset.id;
//         console.log('Escalate clicked for Opportunity ID: ', oppId);
//         this.selectedOpportunityId = oppId;
//         this.showEscalateModal = true;
       
//     }


//     closeRejectModal() {
//         this.showRejectModal = false;
//         this.showRejectModalforMD = false;
//         this.rejectComment = '';
//     }

//     closeEscalateModal() {
//         this.showEscalateModal = false;
//         this.escalateComment = '';
//     }

//     handleCommentChange(event) {
//         this.rejectComment = event.target.value;
//     }

//     handleEscalateCommentChange(event) {
//         this.escalateComment = event.target.value;
//     }

//     submitReject() {
//         if (!this.rejectComment || this.rejectComment.trim() === '') {
//             this.showErrorToast('Please enter a comment before rejecting.');
//             return;
//         }
//         console.log('Rejected Opportunity ID:', this.selectedOpportunityId);
//         console.log('Rejection Comment:', this.rejectComment);

//         rejectOpportunity({ OppId: this.selectedOpportunityId, comment: this.rejectComment })
//             .then(() => {
//                 this.showSuccessToast('Rejected');
//                 this.showRejectModal = false;
//                 this.rejectComment = '';
//                this.domesticOppNH = this.domesticOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
//                this.cellOppNH = this.cellOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
//                this.internationalOpp = this.internationalOpp.filter(opp => opp.Id !== this.selectedOpportunityId);
//             })
//             .catch(error => {
//                 console.error(error);
//                 this.showErrorToast('Error rejecting opportunity');
//             });


//         this.showRejectModal = false;
//         this.rejectComment = '';
//     }
//     submitRejectbyMD() {
//         if (!this.rejectComment || this.rejectComment.trim() === '') {
//             this.showErrorToast('Please enter a comment before rejecting.');
//             return;
//         }
//         console.log('Rejected Opportunity ID:', this.selectedOpportunityId);
//         console.log('Rejection Comment:', this.rejectComment);

//         rejectOpportunitybyMD({ OppId: this.selectedOpportunityId, comment: this.rejectComment })
//             .then(() => {
//                 this.showSuccessToast('Rejected');
//                 this.showRejectModalforMD = false;
//                 this.rejectComment = '';
//                 this.cellOppMD = this.cellOppMD.filter(opp => opp.Id !== this.selectedOpportunityId);
//                 this.domesticOppMD = this.domesticOppMD.filter(opp => opp.Id !== this.selectedOpportunityId);
//             })
//             .catch(error => {
//                 console.error(error);
//                 this.showErrorToast('Error rejecting opportunity');
//             });


//         this.showRejectModalforMD = false;
//         this.rejectComment = '';
//     }
//     submitEscalate() {
//         console.log('Escalation Opportunity ID:', this.selectedOpportunityId);
//         console.log('Escalation Comment:', this.escalateComment);

//         escalateOpportunity({ OppId: this.selectedOpportunityId, comment: this.escalateComment })
//             .then(() => {
//                 this.showSuccessToast('Escalated');
//                 this.showEscalateModal = false;
//                 this.escalateComment = '';
//                 this.domesticOppNH = this.domesticOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
//                 this.cellOppNH = this.cellOppNH.filter(opp => opp.Id !== this.selectedOpportunityId);
//                 this.internationalOpp = this.internationalOpp.filter(opp => opp.Id !== this.selectedOpportunityId);
//             })
//             .catch(error => {
//                 console.error(error);
//                 this.showErrorToast('Error escalating opportunity');
//             });


//         this.showEscalateModal = false;
//         this.escalateComment = '';
//     }

//     showSuccessToast(message) {
//         const event = new ShowToastEvent({
//             title: 'Success',
//             message: message,
//             variant: 'success',
//         });
//         this.dispatchEvent(event);
//     }

//     showErrorToast(message) {
//         const event = new ShowToastEvent({
//             title: 'Error',
//             message: message,
//             variant: 'error',
//             mode: 'dismissable'
//         });
//         this.dispatchEvent(event);
//     }

// }