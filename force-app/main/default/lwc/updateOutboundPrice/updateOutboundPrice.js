import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatePicklistValues from '@salesforce/apex/OutboundLogisticController.getStatePicklistValues';
import getStateAverages from '@salesforce/apex/OutboundLogisticController.getStateAverages';
import updateStatePrice from '@salesforce/apex/OutboundLogisticController.updateStatePrice';

export default class UpdateOutboundPrice extends LightningElement {
    // State management variables
    stateOptions = [];
    selectedState;
    newPrice;
    isLoading = false;
    
    // State averages data
    stateAverages = [];
    overallAverage = 0;
    wiredStateAverages;
    
    // Wire state averages data
    @wire(getStateAverages)
    wiredAverages(result) {
        this.wiredStateAverages = result;
        if (result.data) {
            this.stateAverages = result.data.stateAverages;
            this.overallAverage = result.data.overallAverage;
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }

    // Wire picklist values
    @wire(getStatePicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.stateOptions = data.map(state => ({
                label: state,
                value: state
            }));
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    // Handle state selection
    handleStateChange(event) {
        this.selectedState = event.detail.value;
    }

    // Handle price input
    handlePriceChange(event) {
        this.newPrice = event.detail.value;
    }

    // Check if button should be disabled
    get isButtonDisabled() {
        return !(this.selectedState && this.newPrice);
    }

    // Handle update action
    async handleUpdate() {
        this.isLoading = true;
        try {
            await updateStatePrice({
                selectedState: this.selectedState,
                newPrice: this.newPrice
            });
            
            // Refresh state averages data
            await refreshApex(this.wiredStateAverages);
            
            this.showToast(
                'Success', 
                `Updated price for all ${this.selectedState} records to $${this.newPrice}`,
                'success'
            );
            
            // Reset form
            this.selectedState = null;
            this.newPrice = null;
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Show toast message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}