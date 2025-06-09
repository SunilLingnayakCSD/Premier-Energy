import { LightningElement, wire, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RawMaterialsNamesQueryANdUom from '@salesforce/apex/UimakeApexClass.RawMaterialsNamesQueryANdUom';
import NAME_FIELD from '@salesforce/schema/Raw_Materials__c.Name';
import ID_FIELD from '@salesforce/schema/Raw_Materials__c.Id';

// Define columns for each country
const columnsChina = [
    { label: 'Raw Material name', fieldName: 'Name'},
    { label: 'UOM', fieldName: 'UOM__c' },
    { label: 'China Make1', fieldName: 'China_Make1__c', editable: true },
    { label: 'China Make2', fieldName: 'China_Make2__c', editable: true },
    { label: 'China Make3', fieldName: 'China_Make3__c', editable: true },
    { label: 'China Make4', fieldName: 'China_Make4__c', editable: true },
    { label: 'China Low Price', fieldName: 'China_Low_Price__c' },
    { label: 'China Average', fieldName: 'China_Average_Price__c' },
];

const columnsIndia = [
    { label: 'Raw Material name', fieldName: 'Name' },
    { label: 'UOM', fieldName: 'UOM__c', editable: true },
    { label: 'India Make1', fieldName: 'India_Make1__c', editable: true },
    { label: 'India Make2', fieldName: 'India_Make2__c', editable: true },
    { label: 'India Make3', fieldName: 'India_Make3__c', editable: true },
    { label: 'India Make4', fieldName: 'India_Make4__c', editable: true },
    { label: 'India Low Price', fieldName: 'India_Low_Price__c' },
    { label: 'India Average', fieldName: 'India_Average_Price__c'},
];

const columnsMalaysia = [
    { label: 'Raw Material name', fieldName: 'Name' },
    { label: 'UOM', fieldName: 'UOM__c'},
    { label: 'Malaysia Make1', fieldName: 'Malaysia_Make1__c', editable: true },
    { label: 'Malaysia Make2', fieldName: 'Malaysia_Make2__c', editable: true },
    { label: 'Malaysia Make3', fieldName: 'Malaysia_Make3__c', editable: true },
    { label: 'Malaysia Make4', fieldName: 'Malaysia_Make4__c', editable: true },
    { label: 'Malaysia Low Price', fieldName: 'Malaysia_Low_Price__c' },
    { label: 'Malaysia Average', fieldName: 'Malaysia_Average_Price__c' },
];

const columnsVietnam = [
    { label: 'Raw Material name', fieldName: 'Name' },
    { label: 'UOM', fieldName: 'UOM__c' },
    { label: 'Vietnam Make1', fieldName: 'Vietnam_Make1__c', editable: true },
    { label: 'Vietnam Make2', fieldName: 'Vietnam_Make2__c', editable: true },
    { label: 'Vietnam Make3', fieldName: 'Vietnam_Make3__c', editable: true },
    { label: 'Vietnam Make4', fieldName: 'Vietnam_Make4__c', editable: true },
    { label: 'Vietnam Low Price', fieldName: 'Vietnam_Low_Price__c'},
    { label: 'Vietnam Average', fieldName: 'Vietnam_Average_Price__c' },
];

export default class LwcUiMakes extends LightningElement {
    @track value = '';
    @track columns = [];
    @track searchValue = '';
    @track allData = [];
    @track filteredData = [];
    draftValues = [];
    wiredRawMaterialsResult;

    @wire(RawMaterialsNamesQueryANdUom, { searchKey: '$searchValue' })
    wiredRawMaterials(result) {
        this.wiredRawMaterialsResult = result;
        const { data, error } = result;
        if (data) {
            this.allData = data;
            console.log('All data fetched', this.allData);
        } else if (error) {
            console.error('Error fetching data: ', error.body.message);
            this.showToast('Error', error.body.message, 'error');
        }
    }

    changeHandler(event) {
        this.searchValue = event.target.value;
    }

    handleButtonClick(event) {
        const country = event.target.dataset.country;
        this.value = country;

        switch (country) {
            case 'China':
                this.columns = columnsChina;
                this.filteredData = this.allData.filter(
                    record => record.China_Average_Price__c >=0 ? record.India_Average_Price__c ==0 : record
                );
                break;
            case 'India':
                this.columns = columnsIndia;
                this.filteredData = this.allData.filter(
                    record => record.India_Average_Price__c >0 
                );
                break;
            case 'Malaysia':
                this.columns = columnsMalaysia;
                this.filteredData = this.allData.filter(
                    record => record.Malaysia_Average_Price__c >=0 ? record.India_Average_Price__c ==0 : record
                );
                break;
            case 'Vietnam':
                this.columns = columnsVietnam;
                this.filteredData = this.allData.filter(
                    record => record.Vietnam_Average_Price__c >=0 ? record.India_Average_Price__c ==0 : record
                );
                break;
            default:
                this.columns = [];
                this.filteredData = [];
        }
    }

    async handleSave(event) {
        try {
            const draftValues = event.detail.draftValues;
            
            const recordInputs = draftValues.map(draft => {
                const fields = Object.assign({}, draft);
                return { fields };
            });

            const promises = recordInputs.map(recordInput => updateRecord(recordInput));
            await Promise.all(promises);

            this.showToast('Success', 'Records updated successfully!', 'info');

            this.draftValues = [];
            await refreshApex(this.wiredRawMaterialsResult);

            if (this.value) {
                this.handleButtonClick({ target: { dataset: { country: this.value } } });
            }
        } catch (error) {
            console.error('Error updating records: ', error);
            this.showToast('Error', 'Error updating records: ' + error.body.message, 'error');
        }
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }
}