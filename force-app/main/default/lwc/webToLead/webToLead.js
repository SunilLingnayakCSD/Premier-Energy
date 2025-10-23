import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertLead from '@salesforce/apex/SiteLeadInsert.insertLead';
import belgaumlogo from '@salesforce/resourceUrl/PremierEnergieslogo';
import LightningAlert from 'lightning/alert';
import Account_OBJECT from '@salesforce/schema/Account';
import BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingStateCode';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
//import BebasNeueFont from '@salesforce/resourceUrl/BebasNeueFont';

export default class WebToLead extends LightningElement {
    belgaumlogo = belgaumlogo;
    @track showThankYouMessage = false;
    @track Thankyou = false;
    @track form = true;

    // Country and State handling
    @track countryOptions = [];
    @track stateOptions = [];
    selectedCountry = '';
    selectedState = '';
    isSubmitting = false;
    controllerValues;
    stateValues;
    totalwattageKWdata

    // Form fields
    @track salutation = '';
    @track firstName = '';
    @track lastName = '';
    @track phoneNo = '';
    @track emailId = '';
    @track company = '';
    @track Date = '';
    @track City = '';
    @track PostalCode = '';
    // @track DCRNonDCR = '';
    @track TotalWattageWp = '';
    @track EachModuleWpc = '';
    @track MonthlyUnitsconsumption = '';

    // Error tracking
    @track fieldErrors = {};
    @track duplicateFieldErrors = {
        phone: '',
        Email: '',
    };

    // Wire methods for picklist values
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
        } else if (error) {
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
            this.stateValues = data.values;
        } else if (error) {
            console.error('Error loading state values', error);
        }
    }

    // Computed property to disable state picklist when no country is selected
    get isStateDisabled() {
        return !this.selectedCountry || this.stateOptions.length === 0;
    }


    get submitButtonLabel() {
    return this.isSubmitting ? 'Submitting...' : 'Submit';
}


    // Event handlers
    handleCountryChange(event) {
        this.selectedCountry = event.detail.value;
        this.selectedState = '';
        this.filterStates(this.selectedCountry);
        this.fieldErrors.selectedCountry = '';
    }

    handleStateChange(event) {
        this.selectedState = event.detail.value;
        this.fieldErrors.selectedState = '';
    }

    LeadChangeVal(event) {
        this[event.target.name] = event.target.value;

        // Clear error when field is modified
        if (this.fieldErrors[event.target.name]) {
            this.fieldErrors[event.target.name] = '';
        }
    }

    // Filter states based on selected country
    filterStates(selectedCountry) {
        this.stateOptions = [];
        const controllingValue = this.controllerValues[selectedCountry];

        if (controllingValue === undefined) {
            return;
        }

        this.stateOptions = this.stateValues
            .filter(state => state.validFor.includes(controllingValue))
            .map(state => ({
                label: state.label,
                value: state.value
            }));
    }

    // Validation methods
    validateEmailFormat(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    validatePhoneFormat(phone) {
        const phoneRegex = /^[0-9]{10}$/;
        return phoneRegex.test(phone);
    }

    validateForm() {
        let isValid = true;
        this.fieldErrors = {};

        // Required field validations (company removed from validation)
        const requiredFields = {
            firstName: 'First Name is required',
            lastName: 'Last Name is required',
            emailId: 'Email is required',
            phoneNo: 'Phone Number is required',
            City: 'City is required',
            PostalCode: 'PinCode is required',
            TotalWattageWp: 'Total Capacity in kWp is required',
            selectedCountry: 'Country is required',
            selectedState: 'State is required',
            // DCRNonDCR: 'DCR/Non-DCR is required'
        };

        Object.keys(requiredFields).forEach(field => {
            if (!this[field]) {
                this.fieldErrors[field] = requiredFields[field];
                isValid = false;
            }
        });

        // Email format validation
        if (this.emailId && !this.validateEmailFormat(this.emailId)) {
            this.fieldErrors.emailId = 'Please enter a valid email address';
            isValid = false;
        }

        // Phone format validation
        if (this.phoneNo && !this.validatePhoneFormat(this.phoneNo)) {
            this.fieldErrors.phoneNo = 'Please enter a valid 10-digit phone number';
            isValid = false;
        }

        // Validate TotalWattageWp is a number
        if (this.TotalWattageWp && isNaN(parseFloat(this.TotalWattageWp))) {
            this.fieldErrors.TotalWattageWp = 'Please enter a valid number for Total Capacity';
            isValid = false;
        }

        return isValid;
    }

    // Main submit handler
    async insertLeadAction() {
        console.log('OUTPUT : submit button is clicked');
        console.log('validation : ', this.validateForm);
         if (this.isSubmitting) {
        console.warn('Submission already in progress.');
        return;
    }
        if (this.validateForm()) {
           this.isSubmitting = true;

            // Calculate Project Capacity in MWp
            const projectCapacityMWp = parseFloat(this.TotalWattageWp) / 1000;

            console.log('OUTPUT :-projectCapacityMWp- ', projectCapacityMWp);
            const companyValue = this.company || this.firstName;

            const leadObj = {
                sobjectType: 'Lead',
                Salutation: 'He/She',
                FirstName: this.firstName || 'N/A',
                LastName: this.lastName,
                Phone: this.phoneNo,
                Email: this.emailId,
                Company: companyValue,  // Use first name if company not provided
                CountryCode: this.selectedCountry,
                City: this.City,
                StateCode: this.selectedState,
                PostalCode: this.PostalCode,
                // DCR_Non_DCR1__c: this.DCRNonDCR,
                // Project_Capacity_in_MWp__c: projectCapacityMWp,
                Delivery_Due_Date__c: this.Date,
                Each_Module_Wp__c: this.EachModuleWpc,
                Monthly_Units_consumption__c: this.MonthlyUnitsconsumption,
                Region__c: 'Default',
                LeadSource: 'Web',
                Status: 'New'
            };
            // Conditional capacity fields
            if (projectCapacityMWp >= 1) {
                console.log('OUTPUT : entered into if block', projectCapacityMWp);
                leadObj.Project_Capacity__c = projectCapacityMWp;
            } else {
                console.log('OUTPUT :entered in else block ', projectCapacityMWp);
                leadObj.Total_Capacity_in_MWp__c = projectCapacityMWp;
            }

            console.log('OUTPUT : -----leadObj---->', JSON.stringify(leadObj));


            try {
                const response = await insertLead({ obj: leadObj });
                console.log('OUTPUT : --leadObj sent to apex--');

            /*if (response.status === 'duplicate') {
                console.log('OUTPUT : --Entered into duplicate records--');
                LightningAlert.open({
                    message: response.message || 'A lead with this phone or email already exists.',
                    theme: 'error',
                    label: 'Duplicate Lead',
                });
            }*/ if (response.status === 'success') {
                    console.log('OUTPUT : --Entered into Success--');
                    this.showThankYouMessage = true;
                    LightningAlert.open({
                        message: 'Thank you! Your information has been submitted successfully.',
                        theme: 'success',
                        label: 'Success',
                    });
                    this.resetForm();
                    // this.Thankyou = true;
                    this.form = false;

                }
            } catch (error) {
                console.error('Error:', error);
                LightningAlert.open({
                    message: 'An error occurred while submitting your information. Please try again.',
                    theme: 'error',
                    label: 'Error',
                });
            }
            finally {
            this.isSubmitting = false; // ✅ Allow further submissions after done
        }
        }
    }

    // Reset form fields
    resetForm() {
        // Clear all tracked properties
        this.firstName = '';
        this.lastName = '';
        this.phoneNo = '';
        this.emailId = '';
        this.company = '';
        this.selectedCountry = '';
        this.selectedState = '';
        this.City = '';
        this.PostalCode = '';
        // this.DCRNonDCR = '';
        this.TotalWattageWp = '';
        this.Date = '';
        this.EachModuleWpc = '';
        this.MonthlyUnitsconsumption = '';
        this.fieldErrors = {};

        // Reset comboboxes
        const countryCombobox = this.template.querySelector('lightning-combobox[name="country"]');
        const stateCombobox = this.template.querySelector('lightning-combobox[name="state"]');

        if (countryCombobox) countryCombobox.value = '';
        if (stateCombobox) stateCombobox.value = '';
    }

    // Error message getters
    get firstNameError() { return this.fieldErrors.firstName; }
    get lastNameError() { return this.fieldErrors.lastName; }
    get phoneNoError() { return this.fieldErrors.phoneNo; }
    get emailIdError() { return this.fieldErrors.emailId; }
    get companyError() { return this.fieldErrors.company; }
    get CityError() { return this.fieldErrors.City; }
    get PostalCodeError() { return this.fieldErrors.PostalCode; }
    get CapacityError() { return this.fieldErrors.TotalWattageWp; }
    get CountryError() { return this.fieldErrors.selectedCountry; }
    get StateError() { return this.fieldErrors.selectedState; }
    //get DCRNonDCRError() { return this.fieldErrors.DCRNonDCR; }
    get EachModuleWpcError() { return this.fieldErrors.EachModuleWpc; }
    get DeliverDateError() { return this.fieldErrors.Quantity; }
}