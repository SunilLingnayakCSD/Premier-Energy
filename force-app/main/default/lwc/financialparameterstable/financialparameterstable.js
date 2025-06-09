import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import metadataUpdate from '@salesforce/apex/update_MetaData.metadataUpdate';
import updateMetadata from '@salesforce/apex/update_MetaData.updateMetadata';

export default class FinancialParametersTable extends LightningElement {
    financialParams = {};
    editingField = null;
    wiredMetadataResult;

    // Getter methods for template conditions
    get isEditingUsd() {
        return this.editingField === 'USD_to_INR_CBITC__c';
    }

    get isEditingOverhead() {
        return this.editingField === 'Overhead_cost_mdt__c';
    }

    get isEditingFinanceCost() {
        return this.editingField === 'Finance_Cost__c';
    }
    

    get isEditingcelloverheadCost() {
        return this.editingField === 'Cell_Overhead_Cost__c';
    }
    get isEditingcellFinanceCost() {
        return this.editingField === 'Cell_Finance_Cost__c';
        
    }
    
    get isEditingcellbomCost() {
        return this.editingField === 'Cell_BOM_Cost__c';
        
    }
    get isEditingmodulewarrantyInsurance() {
        return this.editingField === 'ModuleWarrantyInsurance__c';
        
    }
    get isEditingmodulerfidreadercost() {
        return this.editingField === 'RFIDreadercost__c';
        
    }
    get isEditingbgrademodule() {
        return this.editingField === 'B_Grade_Module_Yield__c';
        
    }
     get isEditingbgrademodulediscount() {
        return this.editingField === 'B_Grade_Module_Discount__c';
        
    }
    get isEditingbgradeabgpbgcost() {
        return this.editingField === 'ABGPBGCostPA__c';
        
    }
    get isEditinglcintrest() {
        return this.editingField === 'LCinterestcostPA__c';
        
    }
    get isEditingGst() {
        return this.editingField === 'GST__c';
        
    }
    get isEditinginsurancepremiumcost() {
        return this.editingField === 'InsurnacePremiumcost__c';
        
    }
    
    
    

    
    
    
   

    // Add similar getters for other fields...

    @wire(metadataUpdate)
    wiredMetadata(result) {
        this.wiredMetadataResult = result;
        const { data, error } = result;
        if (data) {
            this.financialParams = { ...data[0] };
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleEdit(event) {
        this.editingField = event.target.dataset.field;
    }

    handleValueChange(event) {
        const field = event.target.dataset.field;
        this.financialParams = {
            ...this.financialParams,
            [field]: event.detail.value
        };
    }

    async handleSave() {
        try {
            await updateMetadata({ params: this.financialParams });
            this.editingField = null;
            await refreshApex(this.wiredMetadataResult);
            this.showToast('Success', 'Value updated successfully', 'success');
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleCancel() {
        refreshApex(this.wiredMetadataResult);
        this.editingField = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}