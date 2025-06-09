import { LightningElement, wire, track } from 'lwc';
import get20FtAnd40Ft from '@salesforce/apex/pricingconfigurationApexClass.get20FtAnd40Ft';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RawMaterialLogger extends LightningElement {
    @track rawdata = [];
    wiredData;

    @wire(get20FtAnd40Ft)
    wiredMaterials(result) {
        this.wiredData = result;
        if (result.data) {
            this.rawdata = result.data.map(item => ({
                ...item,
                isEdit: false,
                tempData: { 
                    Qty_20_Ft__c: item.Qty_20_Ft__c,
                    Qty_40_Ft__c: item.Qty_40_Ft__c
                }
            }));
        }
    }

    handleEdit(event) {
        const id = event.target.dataset.id;
        this.rawdata = this.rawdata.map(item => {
            if (item.Id === id) {
                return { 
                    ...item, 
                    isEdit: true,
                    tempData: {
                        Qty_20_Ft__c: item.Qty_20_Ft__c,
                        Qty_40_Ft__c: item.Qty_40_Ft__c
                    }
                };
            }
            return item;
        });
    }

    handleCancel(event) {
        const id = event.target.dataset.id;
        this.rawdata = this.rawdata.map(item => {
            if (item.Id === id) {
                return { 
                    ...item, 
                    isEdit: false,
                    tempData: {
                        Qty_20_Ft__c: item.Qty_20_Ft__c,
                        Qty_40_Ft__c: item.Qty_40_Ft__c
                    }
                };
            }
            return item;
        });
    }

    async handleSave(event) {
        const id = event.target.dataset.id;
        const material = this.rawdata.find(item => item.Id === id);
        const fields = {
            Id: id,
            Qty_20_Ft__c: material.tempData.Qty_20_Ft__c,
            Qty_40_Ft__c: material.tempData.Qty_40_Ft__c
        };

        try {
            await updateRecord({ fields });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record updated successfully',
                    variant: 'success'
                })
            );
            await refreshApex(this.wiredData);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    handle20FtChange(event) {
        const id = event.target.dataset.id;
        const value = event.target.value;
        this.updateTempData(id, 'Qty_20_Ft__c', value);
    }

    handle40FtChange(event) {
        const id = event.target.dataset.id;
        const value = event.target.value;
        this.updateTempData(id, 'Qty_40_Ft__c', value);
    }

    updateTempData(id, field, value) {
        this.rawdata = this.rawdata.map(item => {
            if (item.Id === id) {
                return {
                    ...item,
                    tempData: {
                        ...item.tempData,
                        [field]: value
                    }
                };
            }
            return item;
        });
    }
}