import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningStudio from '@salesforce/apex/cellwattageapexclass.LightningStudio';
import updateCellWattage from '@salesforce/apex/cellwattageapexclass.updateCellWattage';

export default class CellWattage extends LightningElement {
    @track wattageData;
    @track rows = [];

    @wire(LightningStudio)
    wiredWattageData({ data, error }) {
        if (data) {
            const meta = data[0];
            this.wattageData = {
                m10MonoPERC: meta.Cells_M10_MonoPERC__c,
                m10Topcon: meta.Cells_M10_TOPCON__c,
                m10TopconPlus: meta.Cells_M10_TOPCONS__c,
                g12rTopcon: meta.Cells_G12R_TOPCON__c,
                g12Topcon: meta.Cells_G12_TOPCON__c
            };

            this.rows = [
                { id: 'm10MonoPERC', label: 'Cells M10: MonoPERC', value: meta.Cells_M10_MonoPERC__c, originalValue: meta.Cells_M10_MonoPERC__c, isEditing: false },
                { id: 'm10Topcon', label: 'Cells M10: TOPCON', value: meta.Cells_M10_TOPCON__c, originalValue: meta.Cells_M10_TOPCON__c, isEditing: false },
                { id: 'm10TopconPlus', label: 'Cells M10+: TOPCON', value: meta.Cells_M10_TOPCONS__c, originalValue: meta.Cells_M10_TOPCONS__c, isEditing: false },
                { id: 'g12rTopcon', label: 'Cells G12R: TOPCON', value: meta.Cells_G12R_TOPCON__c, originalValue: meta.Cells_G12R_TOPCON__c, isEditing: false },
                { id: 'g12Topcon', label: 'Cells G12: TOPCON', value: meta.Cells_G12_TOPCON__c, originalValue: meta.Cells_G12_TOPCON__c, isEditing: false }
            ];
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleEdit(event) {
        const id = event.target.dataset.id;
        this.rows = this.rows.map(row => row.id === id ? { ...row, isEditing: true } : row);
    }

    handleValueChange(event) {
        const id = event.target.dataset.id;
        const newValue = event.detail.value;
        this.rows = this.rows.map(row => row.id === id ? { ...row, value: newValue } : row);
    }

    async handleSave(event) {
        const id = event.target.dataset.id;
        const rowToUpdate = this.rows.find(row => row.id === id);

        try {
            await updateCellWattage({
                m10MonoPERC: id === 'm10MonoPERC' ? rowToUpdate.value : this.wattageData.m10MonoPERC,
                m10Topcon: id === 'm10Topcon' ? rowToUpdate.value : this.wattageData.m10Topcon,
                m10TopconPlus: id === 'm10TopconPlus' ? rowToUpdate.value : this.wattageData.m10TopconPlus,
                g12rTopcon: id === 'g12rTopcon' ? rowToUpdate.value : this.wattageData.g12rTopcon,
                g12Topcon: id === 'g12Topcon' ? rowToUpdate.value : this.wattageData.g12Topcon
            });

            // Update local value after save
            this.wattageData[id] = rowToUpdate.value;
            this.rows = this.rows.map(row =>
                row.id === id
                    ? { ...row, originalValue: row.value, isEditing: false }
                    : row
            );

            this.showToast('Success', 'Value updated successfully', 'success');
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleCancel(event) {
        const id = event.target.dataset.id;
        this.rows = this.rows.map(row =>
            row.id === id
                ? { ...row, value: row.originalValue, isEditing: false }
                : row
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}