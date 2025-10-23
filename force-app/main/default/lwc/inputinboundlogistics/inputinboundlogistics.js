import { LightningElement, wire, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import inboundInput from '@salesforce/apex/inputInboundApex.inboundInput';

// Column configurations
const CHINA_COLUMNS = [
    { label: 'Raw Material Name', fieldName: 'Name' },
     { label: 'China BCD %', fieldName: 'China_BCD__c', editable: true },
    { label: 'China ADD %', fieldName: 'China_ADD__c', editable: true },
     { label: 'China CVD %', fieldName: 'China_CVD__c', editable: true },
     { label: 'China SWS %', fieldName: 'China_SWS__c', editable: true },
    { label: 'China AIDC %', fieldName: 'China_AIDC__c', editable: true }
   
   
    
];

const MALAYSIA_COLUMNS = [
    { label: 'Raw Material Name', fieldName: 'Name' },
    { label: 'Malaysia BCD %', fieldName: 'Malaysia_BCD__c', editable: true },
    { label: 'Malaysia ADD %', fieldName: 'Malaysia_ADD__c', editable: true },
     { label: 'Malaysia CVD %', fieldName: 'Malaysia_CVD__c', editable: true },
    { label: 'Malaysia AIDC %', fieldName: 'Malaysia_AIDC__c', editable: true }
    
   
];

const VIETNAM_COLUMNS = [
    { label: 'Raw Material Name', fieldName: 'Name' },
    { label: 'Vietnam BCD %', fieldName: 'Vietnam_Bcd__c', editable: true },
    { label: 'Vietnam ADD %', fieldName: 'Vietnam_ADD__c', editable: true },
    { label: 'Vietnam CVD %', fieldName: 'Vietnam_CVD__c', editable: true },
    { label: 'Vietnam AIDC %', fieldName: 'Vietnam_AIDC__c', editable: true }
];

export default class inputinboundlogistics extends LightningElement {
    @track searchValue = '';
    @track columns = [];
    @track filteredData = [];
    @track allData = [];
    draftValues = [];
    wiredDataResult;
    selectedCountry;

    @wire(inboundInput)
    wiredData(result) {
        this.wiredDataResult = result;
        if (result.data) {
            this.allData = result.data;
            this.filterData();
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }

    handleSearchChange(event) {
        this.searchValue = event.target.value.toLowerCase();
        this.filterData();
    }

    handleCountrySelect(event) {
        this.selectedCountry = event.target.dataset.country;
        switch(this.selectedCountry) {
            case 'China':
                this.columns = CHINA_COLUMNS;
                break;
            case 'Malaysia':
                this.columns = MALAYSIA_COLUMNS;
                break;
            case 'Vietnam':
                this.columns = VIETNAM_COLUMNS;
                break;
        }
        this.filterData();
    }

    filterData() {
        this.filteredData = this.allData.filter(item => {
            const nameMatch = item.Name?.toLowerCase().includes(this.searchValue);
            const countryMatch = this.selectedCountry ? 
                this.hasCountryData(item, this.selectedCountry) : 
                true;
            return nameMatch && countryMatch;
        });
    }

    hasCountryData(item, country) {
        const prefix = country === 'Vietnam' ? 'Vietnam_' : country + '_';
        return Object.keys(item).some(field => 
            field.startsWith(prefix) && item[field] != null
        );
    }

    async handleSave(event) {
        try {
            const records = event.detail.draftValues.map(draft => ({
                fields: {
                    Id: draft.Id,
                    ...this.getCountryFields(this.selectedCountry, draft)
                }
            }));

            const promises = records.map(record => updateRecord(record));
            await Promise.all(promises);

            await refreshApex(this.wiredDataResult);
            this.filterData();
            
            this.draftValues = [];
            this.showToast('Success', 'Records updated successfully!', 'success');
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
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
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}