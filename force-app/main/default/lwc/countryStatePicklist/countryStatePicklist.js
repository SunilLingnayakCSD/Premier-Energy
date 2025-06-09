// //countryStatePicklist.js
// import { LightningElement, track, wire } from 'lwc';
// import getCountryStatePicklists from '@salesforce/apex/StateCountryPicklistController.getCountryStatePicklists';
// import Account_OBJECT from '@salesforce/schema/Account';
// import BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
// import BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingState';
// import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// import { getPicklistValues } from 'lightning/uiObjectInfoApi';
// export default class CountryStatePicklist extends LightningElement {
//     @track countryOptions = [];
//     @track stateOptions = [];
//     @track selectedCountry;
//     @track selectedState;
    
//      //Store complete state data
//     countryStateData = [];

//     @wire(getCountryStatePicklists)
//     wiredPicklistData({ error, data }) {
//         if (data) {
//             console.log('OUTPUT :----->data ',data);
//              //1. Prepare country options
//             this.countryOptions = data.countries.map(country => ({
//                 label: country,
//                 value: country
//             }));

//              //2. Store complete state relationships
//             this.countryStateData = data.states;
//             console.log('OUTPUT :----->countryStateData ',this.countryStateData);
            
//         } else if (error) {
//             console.error('Error loading data:', error);
//         }
//     }

//     get hasStates() {
//         return this.stateOptions.length > 0;
//     }

//     handleCountryChange(event) {
//         this.selectedCountry = event.detail.value;
//         this.selectedState = null;
//         this.updateStateOptions();
//     }

//     updateStateOptions() {
//         //Find states for selected country
//         const countryStates = this.countryStateData.find(
//             item => item.countryCode === this.selectedCountry
//         );

//          //Prepare state options
//         this.stateOptions = countryStates 
//             ? countryStates.states.map(state => ({
//                 label: state,
//                 value: state
//             }))
//             : [];
//     }

//      //extra data
//     @track countryOptions = [];
//     @track stateOptions = [];

//     selectedCountry = '';

//     @wire(getObjectInfo, { objectApiName:Account_OBJECT })
//     accountInfo;

//     @wire(getPicklistValues, {
//         recordTypeId: '$accountInfo.data.defaultRecordTypeId',
//         fieldApiName: BILLING_COUNTRY_FIELD
//     })
//     wiredCountryPicklist({ error, data }) {
//         if (data) {
//             this.countryOptions = data.values.map(item => ({
//                 label: item.label,
//                 value: item.value
//             }));
//         } else {
//             console.error('Error fetching BillingCountry picklist', error);
//         }
//     }

//         dependentRawData;
//     controllerValuesMap;

//     @wire(getPicklistValues, {
//         recordTypeId: '$accountInfo.data.defaultRecordTypeId',
//         fieldApiName: BILLING_STATE_FIELD
//     })
//     wiredStatePicklist({ error, data }) {
//         if (data) {
//             console.log('=================data===================');
//             console.log(JSON.stringify(data));
//             console.log('====================================');
//             this.dependentRawData = data.values;
//             this.controllerValuesMap = data.controllerValues;
//         } else if (error) {
//             console.error('Error fetching BillingState picklist', error);
//         }
//     }


//     handleCountryChange(event) {
//         this.selectedCountry = event.detail.value;

//          //Optionally: filter states here based on selected country if your org supports dependent picklists.
//          //Otherwise, you'll have all states here.
//     }
// }









// countryStatePicklist.js
import { LightningElement, track, wire } from 'lwc';
import Account_OBJECT from '@salesforce/schema/Account';
import BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingStateCode';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class CountryStatePicklist extends LightningElement {
    @track countryOptions = [];
    @track stateOptions = [];
    selectedCountry = '';
    selectedState = '';
    
    controllerValues;
    stateValues;

    @wire(getObjectInfo, { objectApiName: Account_OBJECT })
    accountInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$accountInfo.data.defaultRecordTypeId',
        fieldApiName: BILLING_COUNTRY_FIELD
    })


    wiredCountry({ error, data }) {
        if (data) {
            this.countryOptions = data.values.map(c => ({
                label: c.label,
                value: c.value
            }));
        } else {
            console.error('Error loading country values', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$accountInfo.data.defaultRecordTypeId',
        fieldApiName: BILLING_STATE_FIELD
    })
    wiredState({ error, data }) {
        if (data) {
            this.controllerValues = data.controllerValues;
            console.log('OUTPUT : --->this.controllerValues-->',this.controllerValues);
            this.stateValues = data.values;
            console.log('OUTPUT : --->stateValues---->',this.stateValues);
        } else {
            console.error('Error loading state values', error);
        }
    }

    
    get isStateDisabled() {
    return this.stateOptions.length === 0;
    }

    handleCountryChange(event) {
        this.selectedCountry = event.detail.value;
        this.selectedState = '';
        this.filterStates(this.selectedCountry);
    }

    handleStateChange(event) {
        this.selectedState = event.detail.value;
    }

    filterStates(selectedCountry) {
        this.stateOptions = [];

        const controllingValue = this.controllerValues[selectedCountry];
        console.log('OUTPUT : --controllingValue-->',controllingValue);
        if (controllingValue === undefined) {
            return;
        }
        this.stateOptions = this.stateValues
            .filter(state => state.validFor.includes(controllingValue))
            .map(state => ({
                label: state.label,
                value: state.value
            }));
        console.log('OUTPUT : --stateOptions-->',this.stateOptions);
    }
}