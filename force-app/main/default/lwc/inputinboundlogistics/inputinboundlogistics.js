import { LightningElement, track, wire } from 'lwc';
import inboundInput from '@salesforce/apex/inputInboundApex.inboundInput';
import updateInboundInput from '@salesforce/apex/inputInboundApex.updateInboundInput';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const CHINA_COLUMNS = [
    { label: 'Raw Material Name', fieldName: 'Name' },
    { label: 'China BCD ', fieldName: 'China_BCD__c' },
    { label: 'China ADD ', fieldName: 'China_ADD__c' },
    { label: 'China CVD ', fieldName: 'China_CVD__c' },
    { label: 'China SWS ', fieldName: 'China_SWS__c' },
    { label: 'China AIDC ', fieldName: 'China_AIDC__c' }
];

const MALAYSIA_COLUMNS = [
    { label: 'Raw Material Name', fieldName: 'Name' },
    { label: 'Malaysia BCD ', fieldName: 'Malaysia_BCD__c' },
    { label: 'Malaysia ADD ', fieldName: 'Malaysia_ADD__c' },
    { label: 'Malaysia CVD ', fieldName: 'Malaysia_CVD__c' },
    { label: 'Malaysia AIDC ', fieldName: 'Malaysia_AIDC__c' }
];

const VIETNAM_COLUMNS = [
    { label: 'Raw Material Name', fieldName: 'Name' },
    { label: 'Vietnam BCD ', fieldName: 'Vietnam_Bcd__c' },
    { label: 'Vietnam ADD ', fieldName: 'Vietnam_ADD__c' },
    { label: 'Vietnam CVD ', fieldName: 'Vietnam_CVD__c' },
    { label: 'Vietnam AIDC ', fieldName: 'Vietnam_AIDC__c' }
];

export default class InputInboundLogistics extends LightningElement {
    @track columns = [];
    @track preparedRows = [];
    @track selectedCountry = 'China';

    originalData = [];
    wiredDataResult;
    editedRows = {};

    @wire(inboundInput)
    wiredData(result) {
        this.wiredDataResult = result;
        const { error, data } = result;
        if (data) {
            this.originalData = data;
            this.setCountry(this.selectedCountry);
        } else if (error) {
            console.error('Error loading data:', error);
            this.showToast('Error', error.body.message, 'error');
        }
    }

    get chinaButtonVariant() {
        return this.selectedCountry === 'China' ? 'brand' : 'neutral';
    }
    get malaysiaButtonVariant() {
        return this.selectedCountry === 'Malaysia' ? 'brand' : 'neutral';
    }
    get vietnamButtonVariant() {
        return this.selectedCountry === 'Vietnam' ? 'brand' : 'neutral';
    }

    handleCountrySelect(event) {
        this.setCountry(event.target.dataset.country);
    }

    setCountry(country) {
        this.selectedCountry = country;
        switch (country) {
            case 'China':
                this.columns = CHINA_COLUMNS;
                break;
            case 'Malaysia':
                this.columns = MALAYSIA_COLUMNS;
                break;
            case 'Vietnam':
                this.columns = VIETNAM_COLUMNS;
                break;
            default:
                this.columns = [];
        }
        this.prepareRows();
    }

    prepareRows() {
        this.preparedRows = this.originalData.map(row => {
            const isGlass = row.Name && row.Name.toLowerCase().includes('glass');
            const cells = this.columns.map(col => {
                let cellClass = '';
                let cellTitle = '';
                let displayValue = row[col.fieldName] ?? '';

                if (isGlass) {
                    cellClass = 'glass-cell';
                    if (this.selectedCountry === 'China' && col.fieldName === 'China_ADD__c') {
                        cellClass += ' china-add-cell';
                    }
                }

                const isRawMaterialName = col.fieldName === 'Name';
                const isChinaAddGlass = col.fieldName === 'China_ADD__c' && row.Name && row.Name.toLowerCase().includes('glass');


                // Apply percentage formatting except for Raw Material Name and China ADD
                if (!row.isEditing && !isRawMaterialName && !isChinaAddGlass) {
                    if (displayValue !== '' && displayValue !== null && !isNaN(displayValue)) {
                        displayValue = `${Number(displayValue)}%`;
                    }
                }

                return {
                    fieldName: col.fieldName,
                    value: displayValue,
                    class: cellClass,
                    title: cellTitle,
                    isRawMaterialName
                };
            });

            return {
                Id: row.Id,
                cells,
                rowClass: isGlass ? 'glass-row' : '',
                isEditing: this.editedRows[row.Id]?.isEditing || false,
                draftValues: this.editedRows[row.Id]?.draftValues || {...row}
            };
        });
    }

    handleEditRow(event) {
        const rowId = event.target.dataset.rowId;
        const row = this.originalData.find(r => r.Id === rowId);
        
        this.editedRows[rowId] = {
            isEditing: true,
            draftValues: {...row}
        };
        
        this.prepareRows();
    }

    handleCellChange(event) {
        const rowId = event.target.dataset.rowId;
        const fieldName = event.target.dataset.field;
        let value = event.target.value;
        
        // Remove percentage symbol if user enters it during edit
        if (typeof value === 'string' && value.endsWith('%')) {
            value = value.slice(0, -1);
        }
        
        if (this.editedRows[rowId]) {
            this.editedRows[rowId].draftValues[fieldName] = value;
        }
    }

    handleCancelEdit(event) {
        const rowId = event.target.dataset.rowId;
        delete this.editedRows[rowId];
        this.prepareRows();
    }

    async handleSaveRow(event) {
        const rowId = event.target.dataset.rowId;
        const draftRow = this.editedRows[rowId];
        
        if (!draftRow) return;
        
        try {
            // Prepare the record to update
            const recordToUpdate = {
                Id: rowId,
                ...this.getCountryFields(this.selectedCountry, draftRow.draftValues)
            };
            
            // Update record
            await updateInboundInput({ recordsToUpdate: [recordToUpdate] });
            
            // Show success toast
            this.showToast('Success', 'Row updated successfully', 'success');
            
            // Refresh data
            await refreshApex(this.wiredDataResult);
            
            // Reset edit state
            delete this.editedRows[rowId];
            this.prepareRows();
            
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }

    getCountryFields(country, draft) {
        const fields = {};
        const prefix = country === 'Vietnam' ? 'Vietnam_' : country + '_';
        
        Object.keys(draft).forEach(key => {
            if (key.startsWith(prefix)) {
                fields[key] = draft[key];
            }
        });
        
        return fields;
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