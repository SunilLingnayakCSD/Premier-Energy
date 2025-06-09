import { LightningElement, api, track, wire } from 'lwc';
//import { refreshApex } from '@salesforce/apex';
import getRawMaterialsForOpportunity from '@salesforce/apex/ProductRawMaterialController.getRawMaterialsForOpportunity';

export default class ProductRawMaterialsDisplay extends LightningElement {
    @api recordId;  // The Opportunity ID (recordId)
    @track rawMaterials = [];  // To store raw materials data
    @track error;  // For error handling

    // Fetch OpportunityLineItems and raw materials based on OpportunityId
    @wire(getRawMaterialsForOpportunity, { opportunityId: '$recordId' })
    wiredRawMaterials({ error, data }) {
        if (data) {
            console.log('Raw Materials Data:', JSON.stringify(data, null, 2));
            this.rawMaterials = data.map(rawMaterial => ({
                id: rawMaterial.Id,
                Name: rawMaterial.Raw_Materials__r.Name,
                UOM: rawMaterial.Raw_Materials__r.UOM__c,  // Ensure the UOM is correct
                Quantity: rawMaterial.Raw_Materials__r.Quantity__c,  // Adjust field name if needed
                Price: rawMaterial.Raw_Materials__r.Material_Cost__c  // Adjust field name if needed
            }));
        } else if (error) {
            this.error = error;
            console.error('Error fetching raw materials:', JSON.stringify(error, null, 2));
        }
    }

    // Handle the raw material update event from child
    handleRawMaterialUpdate(event) {
        const updatedRawMaterial = event.detail.updatedRawMaterial;

        // Logic to update the raw materials list in the parent component
        this.rawMaterials = this.rawMaterials.map(rm => 
            rm.id === updatedRawMaterial.id ? updatedRawMaterial : rm
        );
    }

}