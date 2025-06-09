import { LightningElement, api, track, wire } from 'lwc';
import getAllRawMaterials from '@salesforce/apex/ProductRawMaterialController.getAllRawMaterials';
import getSubstituteRawMaterials from '@salesforce/apex/ProductRawMaterialController.getSubstituteRawMaterials'; // Apex method to fetch substitute materials
import updateRawMaterial from '@salesforce/apex/ProductRawMaterialController.updateRawMaterial';


export default class RawMaterialsCostDisplay extends LightningElement {
    @api recordId; // Opportunity ID passed from parent
    @track rawMaterials = []; // Raw materials data
     @track substituteOptions = [];
    @track selectedRawMaterialId; // Store the selected raw material ID
    @track error; // For error handling

    // Fetch all raw materials when component is loaded
    @wire(getAllRawMaterials)
    wiredRawMaterials({ error, data }) {
        if (data) {
            console.log('Raw Materials fetched from Apex:', data);
            // Map data to the format required for the table
            this.rawMaterials = data.map(rawMaterial => ({
                id: rawMaterial.Id,
                name: rawMaterial.Name,
                uom: rawMaterial.UOM__c, // Make sure the field is correct
                quantity: rawMaterial.Quantity__c, // Make sure the field is correct
                cost: rawMaterial.Material_Cost__c, // Make sure the field is correct
                lowCost: rawMaterial.Low_Cost__c, // Make sure the field is correct
                selectedRawMaterial: rawMaterial.Selected__c || '' ,// Use appropriate field for selected material
                selectedSubstituteId: null
            }));
            console.log('Mapped Raw Materials:', this.rawMaterials);
        } else if (error) {
            this.error = error;
            console.error('Error fetching raw materials:', JSON.stringify(error, null, 2));
        }
    }

    @wire(getSubstituteRawMaterials)
    wiredSubstituteRawMaterials({ error, data }) {
        if (data) {
            this.substituteOptions = data.map(substitute => ({
                label: substitute.Name,
                value: substitute.Id
            }));
            console.log('Substitute Raw Materials:', this.substituteOptions);
        } else if (error) {
            this.error = error;
            console.error('Error fetching substitute raw materials:', JSON.stringify(error, null, 2));
        }
    }

    // Handle radio button selection for raw material
    handleRadioChange(event) {
        this.selectedRawMaterialId = event.target.value;
        console.log('Selected Raw Material ID:', this.selectedRawMaterialId);
    }

// Handle the change of selected substitute raw material
handleSubstituteChange(event) {
    const selectedSubstituteId = event.target.value; // Get the selected substitute ID from the dropdown
    const rawMaterialId = event.target.dataset.id;   // Use the data-id from the radio button (ensure it's there)

    // Log the values for debugging
    console.log('Selected Substitute ID:', selectedSubstituteId);
    console.log('Raw Material ID:', rawMaterialId);

    // Update the rawMaterials array with the selected substitute ID
    const updatedRawMaterials = this.rawMaterials.map(rawMaterial => {
        if (rawMaterial.id === rawMaterialId) {
            return { ...rawMaterial, selectedSubstituteId }; // Ensure selectedSubstituteId is set here
        }
        return rawMaterial;
    });

    // Assign the updated rawMaterials to the tracked variable
    this.rawMaterials = updatedRawMaterials;

    // Log updated rawMaterials to check if the substitution is reflected
    console.log('Updated Raw Materials after substitution:', JSON.stringify(this.rawMaterials, null, 2));
}


// Handle the update click event
handleUpdateClick(event) {
    const rawMaterialId = event.target.dataset.id; // Get the raw material ID from the button's data-id
    const updatedRawMaterial = this.rawMaterials.find(rm => rm.id === rawMaterialId); // Find the selected raw material
    console.log('updatedRawMaterial:', updatedRawMaterial);
    const selectedSubstituteId = updatedRawMaterial.selectedSubstituteId; // Get the selected substitute ID

    // Log the values for debugging
    console.log('Selected Raw Material ID:', rawMaterialId);
    console.log('Selected Substitute ID:', selectedSubstituteId);

    // Check if a substitute raw material is selected
    if (selectedSubstituteId) {
        console.log('Updating raw material:', updatedRawMaterial);

        // Call Apex to update the raw material with the selected substitute
        updateRawMaterial({ rawMaterialId, substituteRawMaterialId: selectedSubstituteId })
            .then(() => {
                // Optionally, refresh the raw materials data after the update
                this.rawMaterials = [...this.rawMaterials];  // Re-fetch or update data here if needed
                console.log('Raw material successfully updated');
            })
            .catch(error => {
                console.error('Error updating raw material:', error);
                this.error = error.body.message;
            });

        // Dispatch a custom event to notify the parent component
        const updateEvent = new CustomEvent('rawmaterialupdate', {
            detail: { updatedRawMaterial }
        });

        this.dispatchEvent(updateEvent);
    } else {
        console.log('No substitute raw material selected for update!');
    }
}


}